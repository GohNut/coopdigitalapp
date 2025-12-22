/// PromptPay QR Code Generator ตามมาตรฐาน EMVCo
/// 
/// สำหรับสร้าง QR Code ที่สามารถสแกนด้วยแอปธนาคารไทย
/// แสดงชื่อผู้รับและจำนวนเงินโดยอัตโนมัติ
library;

class PromptPayQrGenerator {
  /// ข้อมูลบัญชีสหกรณ์
  /// ธนาคาร: กรุงไทย
  /// ชื่อบัญชี: สหกรณ์บริการขนส่ง ร.ส.พ. จำกัด
  /// เลขที่บัญชี: 384-0-06010-9
  
  // PromptPay ID ของสหกรณ์ (Tax ID 13 หลัก)
  // TODO: เปลี่ยนเป็น Tax ID จริงของสหกรณ์เพื่อให้ PromptPay ทำงานได้
  static const String coopPromptPayId = '0000000000000'; // Placeholder - ต้องใส่ Tax ID จริง
  
  // ข้อมูลบัญชีธนาคาร (สำหรับแสดงผลเท่านั้น)
  static const String coopBankName = 'ธนาคารกรุงไทย';
  static const String coopAccountName = 'สหกรณ์บริการขนส่ง ร.ส.พ. จำกัด';
  static const String coopAccountNumber = '384-0-06010-9';

  /// สร้าง PromptPay QR Code string สำหรับจำนวนเงินที่กำหนด
  /// 
  /// [amount] - จำนวนเงินที่ต้องการ (บาท)
  /// [promptPayId] - PromptPay ID (เบอร์โทร 10 หลัก, เลขบัตรประชาชน 13 หลัก, หรือ Tax ID 13 หลัก)
  /// 
  /// Returns: QR Code data string ตามมาตรฐาน EMVCo
  static String generate({
    required double amount,
    String? promptPayId,
  }) {
    final id = promptPayId ?? coopPromptPayId;
    
    // Format PromptPay ID (ลบขีด, เพิ่ม 66 ถ้าเป็นเบอร์โทร)
    final formattedId = _formatPromptPayId(id);
    
    // สร้าง EMVCo QR Code payload
    final payload = _buildPayload(formattedId, amount);
    
    // คำนวณและเพิ่ม CRC16
    final crc = _calculateCRC16(payload);
    
    return payload + crc;
  }

  /// Format PromptPay ID ตาม spec
  static String _formatPromptPayId(String id) {
    // ลบขีดและช่องว่าง
    final cleanId = id.replaceAll(RegExp(r'[-\s]'), '');
    
    // ถ้าเป็นเบอร์โทร 10 หลัก แปลงเป็น format 66XXXXXXXXX
    if (cleanId.length == 10 && cleanId.startsWith('0')) {
      return '0066${cleanId.substring(1)}';
    }
    
    // ถ้าเป็น 13 หลัก (บัตรประชาชน/Tax ID)
    if (cleanId.length == 13) {
      return cleanId;
    }
    
    return cleanId;
  }

  /// สร้าง EMVCo payload
  static String _buildPayload(String promptPayId, double amount) {
    final buffer = StringBuffer();
    
    // Payload Format Indicator (ID: 00)
    buffer.write('000201');
    
    // Point of Initiation Method (ID: 01)
    // 11 = Static QR, 12 = Dynamic QR (with amount)
    buffer.write(amount > 0 ? '010212' : '010211');
    
    // Merchant Account Information - PromptPay (ID: 29)
    final merchantInfo = _buildMerchantInfo(promptPayId);
    buffer.write('29${merchantInfo.length.toString().padLeft(2, '0')}$merchantInfo');
    
    // Transaction Currency (ID: 53) - THB = 764
    buffer.write('5303764');
    
    // Transaction Amount (ID: 54) - ถ้ามีจำนวนเงิน
    if (amount > 0) {
      final amountStr = amount.toStringAsFixed(2);
      buffer.write('54${amountStr.length.toString().padLeft(2, '0')}$amountStr');
    }
    
    // Country Code (ID: 58) - TH
    buffer.write('5802TH');
    
    // CRC placeholder (ID: 63) - จะคำนวณทีหลัง
    buffer.write('6304');
    
    return buffer.toString();
  }

  /// สร้าง Merchant Account Information สำหรับ PromptPay
  static String _buildMerchantInfo(String promptPayId) {
    final buffer = StringBuffer();
    
    // Application ID (sub-tag 00) - PromptPay
    buffer.write('0016A000000677010111');
    
    // PromptPay ID type and value
    if (promptPayId.length == 13) {
      // Tax ID หรือ National ID (sub-tag 02)
      buffer.write('02${promptPayId.length.toString().padLeft(2, '0')}$promptPayId');
    } else if (promptPayId.startsWith('0066')) {
      // Mobile number (sub-tag 01)
      buffer.write('01${promptPayId.length.toString().padLeft(2, '0')}$promptPayId');
    } else {
      // Fallback to tax ID format
      buffer.write('02${promptPayId.length.toString().padLeft(2, '0')}$promptPayId');
    }
    
    return buffer.toString();
  }

  /// คำนวณ CRC16-CCITT (0xFFFF)
  static String _calculateCRC16(String data) {
    int crc = 0xFFFF;
    const polynomial = 0x1021;
    
    for (int i = 0; i < data.length; i++) {
      crc ^= (data.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ polynomial) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}

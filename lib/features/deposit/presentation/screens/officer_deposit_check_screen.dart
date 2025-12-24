import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dynamic_deposit_api.dart';
import 'officer_deposit_detail_screen.dart';

class OfficerDepositCheckScreen extends StatefulWidget {
  const OfficerDepositCheckScreen({super.key});

  @override
  State<OfficerDepositCheckScreen> createState() => _OfficerDepositCheckScreenState();
}

class _OfficerDepositCheckScreenState extends State<OfficerDepositCheckScreen> {
  late Future<List<Map<String, dynamic>>> _pendingDepositsFuture;
  final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'th');

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _pendingDepositsFuture = DynamicDepositApiService.getPendingDeposits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ตรวจสอบยอดฝาก', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingDepositsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                   const SizedBox(height: 16),
                   ElevatedButton(onPressed: _refresh, child: const Text('ลองใหม่')),
                ],
              ),
            );
          }

          final deposits = (snapshot.data != null && snapshot.data is List<Map<String, dynamic>>)
              ? snapshot.data!
              : <Map<String, dynamic>>[];

          if (deposits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.inbox, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีรายการรอตรวจสอบ',
                    style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deposits.length,
            itemBuilder: (context, index) {
              final deposit = deposits[index];
              final amount = (deposit['amount'] ?? 0.0).toDouble();
              final date = DateTime.tryParse(deposit['datetime'] ?? '') ?? DateTime.now();
              final refNo = deposit['referenceno'] ?? '-';
              
              // Note: ในรายการ pending อาจจะไม่มีชื่อสมาชิกติดมาใน object deposit_transaction โดยตรง
              // ขึ้นอยู่กับว่า backend join มาให้ไหม ในที่นี้สมมติว่า backend ส่ง accountid มา แล้วเราไปหาชื่อสมาชิกเพิ่ม
              // หรือเบื้องต้นแสดง accountid ไปก่อน
              final accountId = deposit['accountid'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  onTap: () async {
                     final result = await Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (_) => OfficerDepositDetailScreen(
                           deposit: deposit,
                         ),
                       ),
                     );
                     
                     if (result == true) {
                       _refresh();
                     }
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.arrowDownLeft, color: AppColors.warning),
                  ),
                  title: Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('บัญชี: $accountId', style: TextStyle(fontSize: 12)),
                      Text('Ref: $refNo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(dateFormat.format(date), style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

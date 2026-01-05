import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_vision/qr_code_vision.dart' as vision;
import 'package:image/image.dart' as img;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../deposit/domain/deposit_account.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../data/payment_providers.dart';
import '../../domain/payment_service.dart';
import '../../domain/payment_source_model.dart';
import '../../services/qr_save_service.dart';
import '../../../../core/services/image_save_error.dart';
import '../../../notification/domain/notification_model.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import 'package:intl/intl.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _isSavingQrImage = false;
  final MobileScannerController controller = MobileScannerController();
  late TabController _tabController;
  
  // Receive states
  String? _selectedReceiveAccountId;
  final TextEditingController _amountController = TextEditingController();
  bool _showReceiveQr = false;
  double? _initialBalance; // Track initial balance to detect received payments

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    
    // Auto-select account from provider for Receive tab
    final selectedSource = ref.read(selectedPaymentSourceProvider);
    if (selectedSource != null && selectedSource.type == PaymentSourceType.deposit) {
      _selectedReceiveAccountId = selectedSource.sourceId;
    }

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        controller.stop();
        // Update receive account if changed in Pay tab's source card
        final currentSource = ref.read(selectedPaymentSourceProvider);
        if (currentSource != null && currentSource.type == PaymentSourceType.deposit) {
          setState(() {
            _selectedReceiveAccountId = currentSource.sourceId;
          });
        }
      } else {
        controller.start();
      }
      setState(() {});
    });

    // Initialize balance tracking when showing receive QR
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedReceiveAccountId != null) {
        final accountsAsync = ref.read(depositAccountsAsyncProvider);
        accountsAsync.whenData((accounts) {
          final account = accounts.firstWhere(
            (a) => a.id == _selectedReceiveAccountId,
            orElse: () => accounts.first,
          );
          _initialBalance = account.balance;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    _tabController.dispose();
    _amountController.dispose();
    // Cleanup server-side temporary QR if any
    QrSaveService.deleteLastGeneratedQr();
    super.dispose();
  }

  void _refreshSelectedSource() async {
    final currentSource = ref.read(selectedPaymentSourceProvider);
    if (currentSource == null) return;
    ref.invalidate(paymentSourcesProvider);
    final sourcesAsync = await ref.read(paymentSourcesProvider.future);
    final updatedSource = sourcesAsync.firstWhere(
      (s) => s.sourceId == currentSource.sourceId,
      orElse: () => currentSource,
    );
    if (mounted) {
      ref.read(selectedPaymentSourceProvider.notifier).select(updatedSource);
    }
  }

  Future<void> _onQrFound(String code) async {
    print('🎯 [SCAN] _onQrFound called with code: $code');
    print('🎯 [SCAN] _isProcessing = $_isProcessing');
    
    if (_isProcessing) {
      print('⏸️ [SCAN] Already processing, skipping...');
      return;
    }
    
    print('🔍 [SCAN] QR Code found: $code');
    
    final selectedSource = ref.read(selectedPaymentSourceProvider);
    print('🔍 [SCAN] selectedSource = $selectedSource');
    
    if (selectedSource == null) {
      print('❌ [SCAN] No payment source selected');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกบัญชีก่อน')));
      return;
    }
    
    print('✅ [SCAN] Payment source: ${selectedSource.sourceName}');
    setState(() => _isProcessing = true);
    print('✅ [SCAN] Set _isProcessing = true');
    
    try {
      print('🔄 [SCAN] Resolving QR code...');
      final merchant = await paymentServiceProvider.resolveQr(code);
      print('✅ [SCAN] QR resolved: $merchant');
      
      if (mounted) {
        print('🚀 [SCAN] Navigating to payment input...');
        await context.push('/payment/input', extra: {
          ...merchant,
          'selectedSource': selectedSource,
        });
        print('✅ [SCAN] Returned from payment input');
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (e) {
      print('❌ [SCAN] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR ไม่ถูกต้อง: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  String _generateReceiveQrData(DepositAccount account) {
    final amount = _amountController.text.replaceAll(',', '');
    String url = 'coop://pay?account_id=${account.id}&name=${Uri.encodeComponent(account.accountName)}';
    if (amount.isNotEmpty) url += '&amount=$amount';
    return url;
  }

  Future<void> _saveQrImage(DepositAccount account) async {
    if (_isSavingQrImage) return;
    
    setState(() => _isSavingQrImage = true);
    
    try {
      await QrSaveService.saveReceiveQrToGallery(account, _amountController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกรูป QR ลงอัลบั้มรูปแล้ว'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ImageSaveException catch (e) {
      if (mounted) {
        final shouldRetry = await showImageSaveErrorDialog(context, e);
        if (shouldRetry == true) {
          // User wants to retry - call this method recursively
          if (mounted) {
            setState(() => _isSavingQrImage = false);
            await _saveQrImage(account);
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final shouldRetry = await showImageSaveErrorDialog(
          context,
          ImageSaveException(ImageSaveError.unknownError, e.toString()),
        );
        if (shouldRetry == true && mounted) {
          setState(() => _isSavingQrImage = false);
          await _saveQrImage(account);
          return;
        }
      }
    } finally {
      if (mounted) setState(() => _isSavingQrImage = false);
    }
  }



  Future<void> _scanFromGallery() async {
    print('📷 [GALLERY] Starting gallery scan...');
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) {
      print('❌ [GALLERY] No image selected');
      return;
    }

    print('✅ [GALLERY] Image selected: ${image.path}');
    // Don't set _isProcessing here - let _onQrFound handle it
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังสแกนรูปภาพ...'), duration: Duration(seconds: 1)),
      );
    }
    
    try {
      String? code;
      
      if (kIsWeb) {
        print('🌐 [GALLERY] Processing on Web...');
        final bytes = await image.readAsBytes();
        img.Image? decodedImg = img.decodeImage(bytes);
        
        if (decodedImg != null) {
          // 1. First try: Direct scan
          final qrCode = vision.QrCode();
          qrCode.scanRgbaBytes(decodedImg.getBytes(order: img.ChannelOrder.rgba), decodedImg.width, decodedImg.height);
          code = qrCode.content?.text;

          // 2. Second try: Resize if large + Grayscale + Contrast
          if (code == null) {
            // Resize to improve performance and detection on web
            if (decodedImg.width > 1024 || decodedImg.height > 1024) {
              decodedImg = img.copyResize(decodedImg, width: 1024);
            }
            
            final grayscale = img.grayscale(decodedImg);
            final enhanced = img.contrast(grayscale, contrast: 150);
            
            qrCode.scanRgbaBytes(enhanced.getBytes(order: img.ChannelOrder.rgba), enhanced.width, enhanced.height);
            code = qrCode.content?.text;
          }

          // 3. Third try: Higher contrast binarization
          if (code == null) {
             final binarized = img.contrast(decodedImg, contrast: 250);
             qrCode.scanRgbaBytes(binarized.getBytes(order: img.ChannelOrder.rgba), binarized.width, binarized.height);
             code = qrCode.content?.text;
          }
        }
      } else {
        // Mobile logic: Use mobile_scanner (Native)
        print('📱 [GALLERY] Processing on Mobile...');
        final barcodes = await controller.analyzeImage(image.path);
        print('🔍 [GALLERY] Barcodes result: ${barcodes?.barcodes.length ?? 0} barcodes found');
        if (barcodes != null && barcodes.barcodes.isNotEmpty) {
          code = barcodes.barcodes.first.rawValue;
          print('✅ [GALLERY] QR Code extracted: $code');
        }
      }

      if (code != null) {
        print('✅ [GALLERY] QR Code found, calling _onQrFound...');
        await _onQrFound(code);
      } else {
        print('❌ [GALLERY] No QR Code found in image');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบ QR ในรูปภาพ')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอ่านรูปภาพ: $e')),
        );
      }
    }
    // Don't need finally - _onQrFound handles _isProcessing
  }

  @override
  Widget build(BuildContext context) {
    final selectedSource = ref.watch(selectedPaymentSourceProvider);
    final accountsAsync = ref.watch(depositAccountsAsyncProvider);

    return Scaffold(
      backgroundColor: _tabController.index == 0 ? Colors.black : AppColors.background,
      body: Column(
        children: [
          // Unified Header
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: _tabController.index == 0 ? Colors.black.withOpacity(0.5) : AppColors.primary,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () async {
                          // Check if user received money while on Receive tab
                          if (_tabController.index == 1 && _selectedReceiveAccountId != null && _initialBalance != null) {
                            // Refresh accounts first
                            ref.invalidate(depositAccountsAsyncProvider);
                            final accountsAsync = await ref.read(depositAccountsAsyncProvider.future);
                            final selectedAccount = accountsAsync.firstWhere(
                              (a) => a.id == _selectedReceiveAccountId,
                              orElse: () => accountsAsync.first,
                            );
                            
                            // Check if balance increased
                            final balanceDiff = selectedAccount.balance - (_initialBalance ?? 0);
                            if (balanceDiff > 0) {
                              // Create notification for received money
                              ref.read(notificationProvider.notifier).addNotification(
                                NotificationModel.now(
                                  title: 'ได้รับเงินโอน',
                                  message: 'คุณได้รับเงินจำนวน ${NumberFormat('#,##0.00').format(balanceDiff)} บาท',
                                  type: NotificationType.success,
                                ),
                              );
                            }
                          }
                          
                          // Cleanup server-side temporary QR if any
                          await QrSaveService.deleteLastGeneratedQr();
                          
                          context.go('/home');
                        },
                      ),
                      const Text(
                        'จ่าย/รับ',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (_tabController.index == 0)
                        IconButton(
                          icon: ValueListenableBuilder(
                            valueListenable: controller,
                            builder: (context, state, child) {
                              return Icon(
                                state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                                color: state.torchState == TorchState.on ? Colors.yellow : Colors.white,
                              );
                            },
                          ),
                          onPressed: () => controller.toggleTorch(),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'จ่าย (สแกน)'),
                    Tab(text: 'รับ (QR ของฉัน)'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // PAY TAB
                _buildPayTab(selectedSource),
                
                // RECEIVE TAB
                _buildReceiveTab(accountsAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayTab(PaymentSource? selectedSource) {
    if (selectedSource == null) {
       return Center(
         child: ElevatedButton(
           onPressed: () => context.push('/payment/source'),
           child: const Text('เลือกบัญชีจ่ายเงิน'),
         ),
       );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _onQrFound(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        // Overlay logic from original ScanScreen
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(color: Colors.black),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: _isProcessing ? const Center(child: CircularProgressIndicator()) : null,
          ),
        ),
        Positioned(
          top: 20,
          left: 24,
          right: 24,
          child: _buildSourceCard(selectedSource),
        ),
        const Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Text('วาง QR ในกรอบเพื่อสแกน', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBottomAction(
                icon: Icons.image,
                label: 'อัลบั้มภาพ',
                onTap: _scanFromGallery,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiveTab(AsyncValue<List<DepositAccount>> accountsAsync) {
    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) return const Center(child: Text('ไม่พบบัญชีเงินฝาก'));
        
        _selectedReceiveAccountId ??= accounts.first.id;
        
        final selectedAccount = accounts.firstWhere(
          (acc) => acc.id == _selectedReceiveAccountId,
          orElse: () => accounts.first,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('เลือกบัญชีรับเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReceiveAccountId,
                    isExpanded: true,
                    items: accounts.map((acc) => DropdownMenuItem(
                      value: acc.id,
                      child: Text('${acc.accountName} (${acc.accountNumber})'),
                    )).toList(),
                    onChanged: (val) {
                      setState(() { 
                        _selectedReceiveAccountId = val; 
                        _showReceiveQr = false;
                        final accounts = accountsAsync.value!;
                        final account = accounts.firstWhere(
                          (a) => a.id == val,
                          orElse: () => accounts.first,
                        );
                        _initialBalance = account.balance;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('ยอดเงิน (ไม่บังคับ)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '0.00',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (_) => setState(() => _showReceiveQr = false),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showReceiveQr = true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('สร้าง QR'),
                ),
              ),
              if (_showReceiveQr) ...[
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'สแกนเพื่อจ่ายเงิน',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: PrettyQrView.data(
                                data: _generateReceiveQrData(selectedAccount),
                                decoration: const PrettyQrDecoration(
                                  shape: PrettyQrSmoothSymbol(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedAccount.accountName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'เลขที่บัญชี: ${selectedAccount.accountNumber}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            if (_amountController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'ยอดเงิน: ${_amountController.text} บาท',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSavingQrImage ? null : () => _saveQrImage(selectedAccount),
                              icon: _isSavingQrImage
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(_isSavingQrImage ? 'กำลังบันทึก...' : 'บันทึกรูป QR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSourceCard(PaymentSource source) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(source.type.icon, color: source.type.color),
          const SizedBox(width: 12),
          Expanded(child: Text(source.sourceName, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          TextButton(onPressed: () => context.push('/payment/source'), child: const Text('เปลี่ยน')),
        ],
      ),
    );
  }

  Widget _buildBottomAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

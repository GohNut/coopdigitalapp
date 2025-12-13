import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/payment_providers.dart';
import '../../domain/payment_service.dart';
import '../../domain/payment_source_model.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh selected source when app becomes active
    if (state == AppLifecycleState.resumed) {
      _refreshSelectedSource();
    }
  }

  /// Refresh selected payment source with latest balance
  void _refreshSelectedSource() async {
    final currentSource = ref.read(selectedPaymentSourceProvider);
    if (currentSource == null) return;

    // Invalidate and refetch payment sources
    ref.invalidate(paymentSourcesProvider);
    
    // Wait for new data
    final sourcesAsync = await ref.read(paymentSourcesProvider.future);
    
    // Find updated source by ID
    final updatedSource = sourcesAsync.firstWhere(
      (s) => s.sourceId == currentSource.sourceId,
      orElse: () => currentSource,
    );
    
    // Update selected source with fresh balance
    if (mounted) {
      ref.read(selectedPaymentSourceProvider.notifier).select(updatedSource);
    }
  }

  void _onQrFound(String code) async {
    if (_isProcessing) return;
    
    final selectedSource = ref.read(selectedPaymentSourceProvider);
    if (selectedSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกบัญชีก่อน')),
      );
      context.go('/payment/source');
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      final merchant = await paymentServiceProvider.resolveQr(code);
      if (mounted) {
        // Pass both merchant and source to payment input
        await context.push('/payment/input', extra: {
          ...merchant,
          'selectedSource': selectedSource,
        });
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code ไม่ถูกต้อง: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSource = ref.watch(selectedPaymentSourceProvider);

    // Redirect if no source selected
    if (selectedSource == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/payment/source');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mock Camera Preview
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 4),
                borderRadius: BorderRadius.circular(24)
              ),
              width: 300,
              height: 300,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.scanLine, color: Colors.white54, size: 64),
                    SizedBox(height: 16),
                    Text('กำลังเปิดกล้อง...', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          
          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 32),
                        onPressed: () => context.pop(),
                      ),
                      const Text(
                        'สแกน QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Selected Source Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selectedSource.type.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          selectedSource.type.icon,
                          color: selectedSource.type.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'จ่ายจาก: ${selectedSource.sourceName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'ยอดคงเหลือ ${selectedSource.displayBalance}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(
                          'เปลี่ยน',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'วาง QR Code ในกรอบเพื่อสแกน',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                
                const Spacer(),
                
                // Simulate Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _onQrFound('mock-qr-data'),
                      icon: _isProcessing 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          )
                        : const Icon(LucideIcons.scanLine, size: 24),
                      label: Text(
                        _isProcessing ? 'กำลังประมวลผล...' : 'จำลองการสแกนสำเร็จ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

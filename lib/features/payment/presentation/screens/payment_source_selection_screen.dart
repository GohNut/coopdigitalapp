import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/payment_providers.dart';
import '../../domain/payment_source_model.dart';

/// หน้าเลือกแหล่งเงินสำหรับการจ่าย
/// ออกแบบสำหรับคนอายุ 30-50 ปี: ตัวอักษรใหญ่ ปุ่มใหญ่ สีชัดเจน
class PaymentSourceSelectionScreen extends ConsumerStatefulWidget {
  const PaymentSourceSelectionScreen({super.key});

  @override
  ConsumerState<PaymentSourceSelectionScreen> createState() =>
      _PaymentSourceSelectionScreenState();
}

class _PaymentSourceSelectionScreenState
    extends ConsumerState<PaymentSourceSelectionScreen> {
  PaymentSource? _selectedSource;

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(paymentSourcesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'เลือกบัญชีจ่ายเงิน',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.wallet,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'กรุณาเลือกบัญชีที่ต้องการใช้จ่าย',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: sourcesAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'กำลังโหลดข้อมูลบัญชี...',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด: $e',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(paymentSourcesProvider),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
              data: (sources) {
                if (sources.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.walletCards,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ไม่พบบัญชีที่ใช้จ่ายได้',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'กรุณาเปิดบัญชีเงินฝากหรือสมัครสินเชื่อก่อน',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // แบ่งกลุ่มตามประเภท
                final deposits = sources.where((s) => s.type == PaymentSourceType.deposit).toList();
                final loans = sources.where((s) => s.type == PaymentSourceType.loan).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // บัญชีเงินฝาก
                      if (deposits.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: LucideIcons.wallet,
                          title: 'บัญชีเงินฝาก',
                          color: PaymentSourceType.deposit.color,
                        ),
                        const SizedBox(height: 12),
                        ...deposits.map((source) => _buildSourceCard(source)),
                        const SizedBox(height: 24),
                      ],

                      // วงเงินสินเชื่อ
                      if (loans.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: LucideIcons.creditCard,
                          title: 'วงเงินสินเชื่อ',
                          color: PaymentSourceType.loan.color,
                        ),
                        const SizedBox(height: 12),
                        ...loans.map((source) => _buildSourceCard(source)),
                      ],

                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Button
      bottomNavigationBar: _selectedSource != null
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selected source info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedSource!.type.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedSource!.type.icon,
                            color: _selectedSource!.type.color,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedSource!.sourceName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'ยอดคงเหลือ ${_selectedSource!.displayBalance}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Next button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _goToScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ถัดไป - สแกน QR',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceCard(PaymentSource source) {
    final isSelected = _selectedSource == source;
    final color = source.type.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedSource = source),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  source.type.icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.sourceName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (source.accountNumber != null)
                      Text(
                        source.accountNumber!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (source.additionalInfo != null)
                      Text(
                        source.additionalInfo!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),

              // Balance & Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    source.displayBalance,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.green : Colors.grey[400],
                    size: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToScan() {
    if (_selectedSource == null) return;

    // Save selected source to provider
    ref.read(selectedPaymentSourceProvider.notifier).select(_selectedSource!);

    // Navigate to scan screen
    context.push('/scan');
  }
}

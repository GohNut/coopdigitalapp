import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/loan_product_model.dart';
import '../../data/loan_repository_impl.dart';
import 'package:intl/intl.dart';

class LoanProductsScreen extends StatelessWidget {
  const LoanProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = LoanRepositoryImpl();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประเภทเงินกู้'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: FutureBuilder<List<LoanProduct>>(
        future: repository.getLoanProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
             return const Center(child: Text('ไม่พบประเภทสินเชื่อ'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = products[index];
              return _LoanProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}

class _LoanProductCard extends StatelessWidget {
  final LoanProduct product;

  const _LoanProductCard({required this.product});

  String _getCollateralDescription(LoanProduct product) {
    // Logic to derive collateral description since it's not in JSON
    if (product.id == 'housing') return 'จำนองโฉนดที่ดิน';
    if (product.id == 'emergency') return 'ใช้หุ้นค้ำประกัน';
    if (product.requireGuarantor) return 'บุคคลค้ำประกัน';
    
    // Fallback based on conditions if available
    for (var condition in product.conditions) {
      if (condition.contains('หลักทรัพย์')) return 'หลักทรัพย์ค้ำประกัน';
      if (condition.contains('หุ้น')) return 'ใช้หุ้นค้ำประกัน';
    }
    
    return 'ไม่ระบุ';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: () {
          context.push('/loan/calculate/${product.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: AppColors.primary.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: const Icon(LucideIcons.banknote, color: AppColors.primary),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           product.name,
                           style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                         ),
                          Text(
                            product.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'หลักประกัน: ${_getCollateralDescription(product)}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                       ],
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   _buildInfoChip(context, 'วงเงินสูงสุด', NumberFormat.compact(locale: 'th').format(product.maxAmount)),
                   _buildInfoChip(context, 'ดอกเบี้ย', '${product.interestRate}%'),
                   _buildInfoChip(context, 'ผ่อนนาน', '${product.maxMonths} งวด'),
                 ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }
}

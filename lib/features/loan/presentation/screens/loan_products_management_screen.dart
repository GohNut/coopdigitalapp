import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/user_role.dart';
import '../../domain/loan_product_model.dart';
import '../../data/loan_repository_impl.dart';
import 'package:intl/intl.dart';

/// หน้าจัดการประเภทเงินกู้ สำหรับเจ้าหน้าที่
class LoanProductsManagementScreen extends StatefulWidget {
  const LoanProductsManagementScreen({super.key});

  @override
  State<LoanProductsManagementScreen> createState() => _LoanProductsManagementScreenState();
}

class _LoanProductsManagementScreenState extends State<LoanProductsManagementScreen> {
  final repository = LoanRepositoryImpl();
  late Future<List<LoanProduct>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    _productsFuture = repository.getLoanProducts();
  }

  void _refreshProducts() {
    setState(() {
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check permission
    if (!CurrentUser.isOfficerOrApprover) {
      return Scaffold(
        appBar: AppBar(title: const Text('กำหนดประเภทเงินกู้')),
        body: const Center(
          child: Text('คุณไม่มีสิทธิ์เข้าถึงหน้านี้'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('กำหนดประเภทเงินกู้'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          // ปุ่ม + มุมขวาบน
          IconButton(
            onPressed: () async {
              final result = await context.push('/loan-products-management/create');
              if (result == true) {
                _refreshProducts();
              }
            },
            icon: const Icon(LucideIcons.plus, size: 24),
            tooltip: 'เพิ่มประเภทเงินกู้',
          ),
        ],
      ),
      body: FutureBuilder<List<LoanProduct>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.alertCircle, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshProducts,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data ?? [];
          
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileText, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีประเภทเงินกู้',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ปุ่มเพิ่มประเภทเงินกู้สำหรับหน้าว่าง
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await context.push('/loan-products-management/create');
                      if (result == true) {
                        _refreshProducts();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(LucideIcons.plus),
                    label: const Text(
                      'เพิ่มประเภทเงินกู้',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }

          // ListView มี products + 1 (ปุ่มเพิ่มเมื่อเลื่อนลงสุด)
          return RefreshIndicator(
            onRefresh: () async => _refreshProducts(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length + 1, // +1 สำหรับปุ่มด้านล่าง
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // รายการสุดท้ายเป็นปุ่มเพิ่ม
                if (index == products.length) {
                  return _buildAddButton(context);
                }
                
                final product = products[index];
                return _ProductManagementCard(
                  product: product,
                  onEdit: () async {
                    final result = await context.push(
                      '/loan-products-management/edit/${product.id}',
                      extra: product,
                    );
                    if (result == true) {
                      _refreshProducts();
                    }
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('ยืนยันการลบ'),
                        content: Text('ต้องการลบ "${product.name}" หรือไม่?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('ยกเลิก'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('ลบ'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      try {
                        await repository.deleteLoanProduct(product.id);
                        _refreshProducts();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ลบประเภทเงินกู้เรียบร้อย')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                          );
                        }
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ปุ่มเพิ่มประเภทเงินกู้ที่ด้านล่างสุดของ list
  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await context.push('/loan-products-management/create');
          if (result == true) {
            _refreshProducts();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: const Icon(LucideIcons.plus, size: 22),
        label: const Text(
          'เพิ่มประเภทเงินกู้',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ProductManagementCard extends StatelessWidget {
  final LoanProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductManagementCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'th');
    
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.id,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(LucideIcons.edit, color: AppColors.primary),
                  tooltip: 'แก้ไข',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(LucideIcons.trash2, color: Colors.red.shade400),
                  tooltip: 'ลบ',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  context,
                  icon: LucideIcons.banknote,
                  label: 'วงเงินสูงสุด',
                  value: '${currencyFormat.format(product.maxAmount)} บาท',
                ),
                _buildInfoChip(
                  context,
                  icon: LucideIcons.percent,
                  label: 'ดอกเบี้ย',
                  value: '${product.interestRate}% ต่อปี',
                ),
                _buildInfoChip(
                  context,
                  icon: LucideIcons.calendar,
                  label: 'ผ่อนสูงสุด',
                  value: '${product.maxMonths} งวด',
                ),
                if (product.requireGuarantor)
                  _buildInfoChip(
                    context,
                    icon: LucideIcons.userCheck,
                    label: 'ผู้ค้ำ',
                    value: 'ต้องมี',
                    color: Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

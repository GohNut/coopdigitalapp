import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/share_repository_impl.dart';
import '../../domain/models/share_type.dart';

class OfficerShareTypeManagementScreen extends StatefulWidget {
  const OfficerShareTypeManagementScreen({super.key});

  @override
  State<OfficerShareTypeManagementScreen> createState() => _OfficerShareTypeManagementScreenState();
}

class _OfficerShareTypeManagementScreenState extends State<OfficerShareTypeManagementScreen> {
  final _repository = ShareRepositoryImpl();
  List<ShareType> _shareTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShareTypes();
  }

  Future<void> _loadShareTypes() async {
    setState(() => _isLoading = true);
    try {
      final types = await _repository.getShareTypes();
      setState(() {
        _shareTypes = types.where((t) => t.status == 'active').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading share types: $e')),
        );
      }
    }
  }

  Future<void> _showShareTypeDialog({ShareType? shareType}) async {
    final nameController = TextEditingController(text: shareType?.name ?? '');
    final priceController = TextEditingController(text: shareType?.price.toString() ?? '');
    final isEditing = shareType != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'แก้ไขประเภทหุ้น' : 'เพิ่มประเภทหุ้น'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'ชื่อหุ้น (เช่น หุ้นสามัญ)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'ราคาต่อหน่วย'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) return;
              
              final price = double.tryParse(priceController.text) ?? 0.0;
              final newShareType = ShareType(
                id: shareType?.id ?? '',
                name: nameController.text,
                price: price,
                status: shareType?.status ?? 'active',
              );

              try {
                if (isEditing) {
                  await _repository.updateShareType(newShareType);
                } else {
                  await _repository.createShareType(newShareType);
                }
                if (mounted) {
                  Navigator.pop(context);
                  _loadShareTypes();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isEditing ? 'บันทึก' : 'สร้าง'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShareType(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบประเภทหุ้นนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteShareType(id);
        _loadShareTypes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการประเภทหุ้น'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(), 
        ),
        actions: [
          // ปุ่ม + มุมขวาบน
          IconButton(
            onPressed: () => _showShareTypeDialog(),
            icon: const Icon(LucideIcons.plus, size: 24),
            tooltip: 'เพิ่มประเภทหุ้น',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shareTypes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadShareTypes,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shareTypes.length + 1, // +1 สำหรับปุ่มด้านล่าง
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      // รายการสุดท้ายเป็นปุ่มเพิ่ม
                      if (index == _shareTypes.length) {
                        return _buildAddButton();
                      }
                      
                      final type = _shareTypes[index];
                      return _ShareTypeCard(
                        shareType: type,
                        onEdit: () => _showShareTypeDialog(shareType: type),
                        onDelete: () => _deleteShareType(type.id),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.candlestickChart, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีประเภทหุ้น',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showShareTypeDialog(),
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
              'เพิ่มประเภทหุ้น',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () => _showShareTypeDialog(),
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
          'เพิ่มประเภทหุ้น',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ShareTypeCard extends StatelessWidget {
  final ShareType shareType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShareTypeCard({
    required this.shareType,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.candlestickChart, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shareType.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.banknote, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${shareType.price} บาท/หุ้น',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}

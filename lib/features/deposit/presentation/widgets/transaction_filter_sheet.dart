import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/deposit_providers.dart';
import '../../domain/deposit_transaction.dart';

/// BottomSheet สำหรับกรองรายการเดินบัญชี
class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key});

  @override
  ConsumerState<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends ConsumerState<TransactionFilterSheet> {
  late int _selectedMonth;
  late int _selectedYear;
  final Set<TransactionType> _selectedTypes = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final currentFilter = ref.read(transactionFilterProvider);
    
    _selectedMonth = currentFilter.startDate?.month ?? now.month;
    _selectedYear = currentFilter.startDate?.year ?? now.year;
    
    if (currentFilter.types != null) {
      _selectedTypes.addAll(currentFilter.types!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'กรองรายการ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilter,
                child: const Text('ล้างตัวกรอง'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Month & Year Selection
          Text(
            'เลือกเดือน/ปี',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Month Dropdown
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      items: List.generate(12, (i) {
                        final month = i + 1;
                        return DropdownMenuItem(
                          value: month,
                          child: Text(_getThaiMonth(month)),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedMonth = value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Year Dropdown
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      items: years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text('${year + 543}'), // Convert to Buddhist year
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedYear = value);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Transaction Type Selection
          Text(
            'ประเภทรายการ',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TransactionType.values.map((type) {
              final isSelected = _selectedTypes.contains(type);
              return FilterChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTypes.add(type);
                    } else {
                      _selectedTypes.remove(type);
                    }
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyFilter,
              icon: const Icon(LucideIcons.check),
              label: const Text('ใช้ตัวกรอง'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilter() {
    final startDate = DateTime(_selectedYear, _selectedMonth, 1);
    final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0); // Last day of month

    ref.read(transactionFilterProvider.notifier).setFilter(TransactionFilter(
      startDate: startDate,
      endDate: endDate,
      types: _selectedTypes.isEmpty ? null : _selectedTypes.toList(),
    ));

    Navigator.pop(context);
  }

  void _clearFilter() {
    ref.read(transactionFilterProvider.notifier).clear();
    Navigator.pop(context);
  }

  String _getThaiMonth(int month) {
    const months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return months[month - 1];
  }
}

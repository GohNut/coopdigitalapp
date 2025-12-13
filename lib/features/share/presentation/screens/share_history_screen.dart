import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/mock_share_repository.dart';
import '../../domain/models/share_transaction.dart';

class ShareHistoryScreen extends StatefulWidget {
  const ShareHistoryScreen({super.key});

  @override
  State<ShareHistoryScreen> createState() => _ShareHistoryScreenState();
}

class _ShareHistoryScreenState extends State<ShareHistoryScreen> {
  final _repository = MockShareRepository();
  List<ShareTransaction> _allTransactions = [];
  List<ShareTransaction> _filteredTransactions = [];
  bool _isLoading = true;

  // Filter State
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedShareType = 'ทั้งหมด';
  String _selectedStatus = 'ทั้งหมด';

  final List<String> _shareTypes = ['ทั้งหมด', 'หุ้นสามัญ'];
  final List<String> _statuses = ['ทั้งหมด', 'ซื้อรายเดือน', 'ซื้อพิเศษ', 'ปันผล', 'ขาย', 'โอน'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _repository.getHistory();
    if (mounted) {
      setState(() {
        _allTransactions = data;
        _filteredTransactions = data;
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        // Date Range Filter
        if (_startDate != null && tx.date.isBefore(_startDate!)) return false;
        if (_endDate != null && tx.date.isAfter(_endDate!.add(const Duration(days: 1)))) return false;

        // Status Filter
        if (_selectedStatus != 'ทั้งหมด') {
          if (_selectedStatus == 'ซื้อรายเดือน' && tx.type != ShareTransactionType.monthlyBuy) return false;
          if (_selectedStatus == 'ซื้อพิเศษ' && tx.type != ShareTransactionType.extraBuy) return false;
          if (_selectedStatus == 'ปันผล' && tx.type != ShareTransactionType.dividend) return false;
          // ขาย/โอน not in current mock, but structure is ready
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedShareType = 'ทั้งหมด';
      _selectedStatus = 'ทั้งหมด';
      _filteredTransactions = _allTransactions;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final dateFormat = DateFormat("d MMM yyyy", "th_TH");
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('กรองข้อมูล', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    }, child: const Text('ล้างทั้งหมด', style: TextStyle(color: Colors.red))),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Date Range
                const Text('ช่วงวันที่', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.calendarDays, size: 18),
                        label: Text(_startDate != null ? dateFormat.format(_startDate!) : 'เริ่มต้น'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => _startDate = picked);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-'),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.calendarDays, size: 18),
                        label: Text(_endDate != null ? dateFormat.format(_endDate!) : 'สิ้นสุด'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => _endDate = picked);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Share Type
                const Text('ประเภทหุ้น', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _shareTypes.map((type) {
                    final isSelected = _selectedShareType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      onSelected: (val) {
                        setSheetState(() => _selectedShareType = type);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 3. Status (ซื้อ/ขาย/โอน)
                const Text('สถานะ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statuses.map((status) {
                    final isSelected = _selectedStatus == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      onSelected: (val) {
                        setSheetState(() => _selectedStatus = status);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Apply Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ค้นหา', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('ประวัติหุ้น'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter, color: Colors.white),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.searchX, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('ไม่พบรายการที่ตรงกับเงื่อนไข', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionItem(_filteredTransactions[index]);
                  },
                ),
    );
  }

  Widget _buildTransactionItem(ShareTransaction transaction) {
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");
    final dateFormat = DateFormat("d MMM yyyy", "th_TH");
    
    IconData icon;
    Color color;
    Color bgColor;

    switch (transaction.type) {
      case ShareTransactionType.monthlyBuy:
        icon = LucideIcons.calendarClock;
        color = Colors.blue;
        bgColor = Colors.blue.shade50;
        break;
      case ShareTransactionType.extraBuy:
        icon = LucideIcons.plusCircle;
        color = Colors.green;
        bgColor = Colors.green.shade50;
        break;
      case ShareTransactionType.dividend:
        icon = LucideIcons.gift;
        color = Colors.orange;
        bgColor = Colors.orange.shade50;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  dateFormat.format(transaction.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${currencyFormat.format(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              Text(
                '${transaction.units} หุ้น',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/dividend_repository_impl.dart';
import '../../domain/models/dividend_model.dart';

class DividendDetailScreen extends StatefulWidget {
  const DividendDetailScreen({super.key});

  @override
  State<DividendDetailScreen> createState() => _DividendDetailScreenState();
}

class _DividendDetailScreenState extends State<DividendDetailScreen> {
  final _repository = DividendRepositoryImpl();
  DividendSummary? _summary;
  DividendRate? _rate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currentYear = DateTime.now().year;
    final summary = await _repository.calculateDividend(currentYear);
    final rate = await _repository.getCurrentDividendRate();
    
    if (mounted) {
      setState(() {
        _summary = summary;
        _rate = rate;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('เงินปันผล'),
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
            icon: const Icon(LucideIcons.history),
            onPressed: () => context.push('/share/dividend/history'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    _buildSummaryCard(currencyFormat),
                    const SizedBox(height: 24),
                    
                    // Details Card
                    _buildDetailsCard(currencyFormat),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    if (_summary!.status == 'pending' && _summary!.totalAmount > 0)
                      _buildRequestButton(),
                      
                    const SizedBox(height: 16),
                    
                    // Status Info
                    _buildStatusInfo(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EFF), Color(0xFF9747FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.gift, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text('เงินปันผลโดยประมาณ', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${currencyFormat.format(_summary?.totalAmount ?? 0)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'อัตราปันผล ${_rate?.rate ?? 0}% ต่อปี',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('รายละเอียดการคำนวณ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildDetailRow('ปีบัญชี', '${_summary?.year ?? DateTime.now().year}'),
          const Divider(height: 24),
          _buildDetailRow('มูลค่าหุ้นเฉลี่ย', '${currencyFormat.format(_summary?.averageShares ?? 0)}'),
          const Divider(height: 24),
          _buildDetailRow('อัตราปันผล', '${_rate?.rate ?? 0}%'),
          const Divider(height: 24),
          _buildDetailRow('เงินปันผล', '${currencyFormat.format(_summary?.totalAmount ?? 0)}', isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value, 
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: isHighlight ? 18 : 14,
            color: isHighlight ? AppColors.primary : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/share/dividend/request', extra: {
          'year': _summary?.year,
          'amount': _summary?.totalAmount,
          'rate': _rate?.rate,
        }),
        icon: const Icon(LucideIcons.wallet, color: Colors.white),
        label: const Text('ขอรับเงินปันผล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildStatusInfo() {
    final status = _summary?.status ?? 'pending';
    final isPaid = status == 'paid';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPaid ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? LucideIcons.checkCircle : LucideIcons.clock,
            color: isPaid ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPaid 
                  ? 'คุณได้รับเงินปันผลปี ${_summary?.year} เรียบร้อยแล้ว'
                  : 'รอประกาศจ่ายเงินปันผลจากสหกรณ์',
              style: TextStyle(color: isPaid ? Colors.green.shade700 : Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

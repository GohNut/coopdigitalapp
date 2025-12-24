import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dynamic_withdrawal_api.dart';
import 'officer_withdrawal_detail_screen.dart';

class OfficerWithdrawalCheckScreen extends StatefulWidget {
  const OfficerWithdrawalCheckScreen({super.key});

  @override
  State<OfficerWithdrawalCheckScreen> createState() => _OfficerWithdrawalCheckScreenState();
}

class _OfficerWithdrawalCheckScreenState extends State<OfficerWithdrawalCheckScreen> {
  late Future<List<Map<String, dynamic>>> _pendingWithdrawalsFuture;
  final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'th');

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _pendingWithdrawalsFuture = DynamicWithdrawalApiService.getPendingWithdrawals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ตรวจสอบการถอนเงิน', style: TextStyle(color: Colors.white)),
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
        future: _pendingWithdrawalsFuture,
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

          final withdrawals = (snapshot.data != null && snapshot.data is List<Map<String, dynamic>>)
              ? snapshot.data!
              : <Map<String, dynamic>>[];

          if (withdrawals.isEmpty) {
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
            itemCount: withdrawals.length,
            itemBuilder: (context, index) {
              final withdrawal = withdrawals[index];
              
              // Robust parsing
              double amount = 0.0;
              final rawAmount = withdrawal['amount'];
              if (rawAmount is num) {
                amount = rawAmount.toDouble();
              } else if (rawAmount is String) {
                amount = double.tryParse(rawAmount) ?? 0.0;
              }

              final date = DateTime.tryParse(withdrawal['datetime'] ?? '') ?? DateTime.now();
              final destinationBank = withdrawal['destination_bank'] ?? '-';
              final destinationAccount = withdrawal['destination_account'] ?? '-';
              final accountId = withdrawal['accountid'] ?? '';

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
                         builder: (_) => OfficerWithdrawalDetailScreen(
                           withdrawal: withdrawal,
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
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.arrowUpRight, color: AppColors.error),
                  ),
                  title: Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('จากบัญชี: $accountId', style: const TextStyle(fontSize: 12)),
                      Text('ไปยัง: $destinationBank ($destinationAccount)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(dateFormat.format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

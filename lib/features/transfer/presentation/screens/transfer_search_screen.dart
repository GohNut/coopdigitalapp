import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dynamic_deposit_api.dart';

class TransferSearchScreen extends StatefulWidget {
  const TransferSearchScreen({super.key});

  @override
  State<TransferSearchScreen> createState() => _TransferSearchScreenState();
}

class _TransferSearchScreenState extends State<TransferSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _foundAccount;
  String? _error;

  void _search() async {
    final key = _searchController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _foundAccount = null;
    });

    try {
      // Search by Account ID (for simplified demo, assuming user knows Account ID or Number)
      // In real app, might search by member ID then pick account.
      // Here we assume key is Account Number or ID.
      // Let's try to query 'getAccountById' (if key is ID) or we need a search by number.
      // Our API 'getAccountById' currently takes accountId.
      // Let's assume input is Account ID for now to be safe with existing simple API, 
      // or we can try to fetch all accounts and filter (bad for scale but ok for dev).
      // better: use getAccountById directly.
      
      final account = await DynamicDepositApiService.getAccountById(key);
      
      if (account != null) {
        setState(() {
          _foundAccount = account;
        });
      } else {
         setState(() {
          _error = 'ไม่พบบัญชีเงินฝาก';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'ไม่พบข้อมูลบัญชีหรือเกิดข้อผิดพลาด';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectAccount() {
    if (_foundAccount != null) {
      context.push('/transfer/input', extra: _foundAccount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('โอนเงินสมาชิก'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('ระบุเลขที่บัญชีปลายทาง (Account ID)', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'เช่น acc_123456...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: const Text('ค้นหา', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
            
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            else if (_foundAccount != null)
              GestureDetector(
                onTap: _selectAccount,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Row(
                    children: [
                       Container(
                         width: 50,
                         height: 50,
                         decoration: BoxDecoration(
                           color: AppColors.primary.withOpacity(0.1),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(LucideIcons.user, color: AppColors.primary),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               _foundAccount!['accountname'] ?? 'ไม่ระบุชื่อ',
                               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                             ),
                             Text(
                               'เลขบัญชี: ${_foundAccount!['accountnumber']}\nID: ${_foundAccount!['accountid']}',
                               style: const TextStyle(color: AppColors.textSecondary),
                             ),
                           ],
                         ),
                       ),
                       const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

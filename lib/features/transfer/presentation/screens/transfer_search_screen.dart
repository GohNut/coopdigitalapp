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
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  Map<String, dynamic>? _foundAccount;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _search() async {
    final key = _searchController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _foundAccount = null;
    });

    try {
      // Search by Account Number
      final account = await DynamicDepositApiService.getAccountByNumber(key);
      
      if (account != null) {
        setState(() {
          _foundAccount = account;
        });
      } else {
         // Fallback: try search by ID just in case
         final accountById = await DynamicDepositApiService.getAccountById(key);
         if (accountById != null) {
            setState(() {
              _foundAccount = accountById;
            });
         } else {
            setState(() {
              _error = 'ไม่พบบัญชีเงินฝาก';
            });
         }
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
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: _searchFocusNode.hasFocus ? null : 'เช่น acc_123456...',
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
                               overflow: TextOverflow.ellipsis,
                             ),
                             Text(
                               'เลขบัญชี: ${_foundAccount!['accountnumber']}\nID: ${_foundAccount!['accountid']}',
                               style: const TextStyle(color: AppColors.textSecondary),
                               overflow: TextOverflow.ellipsis,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/financial_refresh_provider.dart';
import '../../../../services/dynamic_deposit_api.dart';

class TransferSearchScreen extends ConsumerStatefulWidget {
  const TransferSearchScreen({super.key});

  @override
  ConsumerState<TransferSearchScreen> createState() => _TransferSearchScreenState();
}

class _TransferSearchScreenState extends ConsumerState<TransferSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  Map<String, dynamic>? _foundAccount;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
    
    // Refresh financial data when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(financialRefreshProvider.notifier).refreshDepositAndLoan();
      }
    });
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
      // 1. Search by Account Number (เดิม)
      final account = await DynamicDepositApiService.getAccountByNumber(key);
      
      if (account != null) {
        setState(() {
          _foundAccount = account;
        });
      } else {
         // 2. ถ้าคีย์ที่กรอกขึ้นต้นด้วย 'M' ให้หาด้วย Member Number
         if (key.startsWith('M') || key.startsWith('m')) {
           final accountByMember = await DynamicDepositApiService.getAccountsByMemberNumber(key.toUpperCase());
           if (accountByMember != null) {
             setState(() {
               _foundAccount = accountByMember;
             });
             return;
           }
         }

         // 3. Fallback: try search by ID just in case
         final accountById = await DynamicDepositApiService.getAccountById(key);
         if (accountById != null) {
            setState(() {
              _foundAccount = accountById;
            });
         } else {
            setState(() {
              _error = 'ไม่พบบัญชีปลายทาง (แนะนำ: ค้นด้วยหมายเลขสมาชิก เช่น M12345)';
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
    final refreshState = ref.watch(financialRefreshProvider);
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('โอนเงิน'),
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
            // ส่วนโอนเงินระหว่างบัญชีของฉัน
            GestureDetector(
              onTap: () => context.push('/transfer/own'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF4A90D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.repeat, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'โอนเงินระหว่างบัญชีของฉัน',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'โอนเงินระหว่างบัญชีออมทรัพย์ของคุณ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // Divider with text
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('หรือ', style: TextStyle(color: AppColors.textSecondary)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            
            const SizedBox(height: 24),

            // ส่วนโอนเงินให้สมาชิกอื่น
            const Text(
              'โอนเงินให้สมาชิกอื่น',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
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
      ),
        // Loading Overlay
        if (refreshState.isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'กำลังโหลดข้อมูล...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

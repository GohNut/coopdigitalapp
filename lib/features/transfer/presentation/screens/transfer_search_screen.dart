import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/transfer_service.dart';

class TransferSearchScreen extends StatefulWidget {
  const TransferSearchScreen({super.key});

  @override
  State<TransferSearchScreen> createState() => _TransferSearchScreenState();
}

class _TransferSearchScreenState extends State<TransferSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _foundMember;
  String? _error;

  void _search() async {
    final key = _searchController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _foundMember = null;
    });

    try {
      final member = await transferServiceProvider.searchMember(key);
      setState(() {
        _foundMember = member;
      });
    } catch (e) {
      setState(() {
        _error = 'ไม่พบข้อมูลสมาชิก';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectMember() {
    if (_foundMember != null) {
      context.push('/transfer/input', extra: _foundMember);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('โอนเงิน'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('ระบุเลขสมาชิก หรือ เบอร์โทรศัพท์', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'ค้นหา...',
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
            else if (_foundMember != null)
              GestureDetector(
                onTap: _selectMember,
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
                           color: Colors.grey[200],
                           shape: BoxShape.circle,
                           image: DecorationImage(
                             image: NetworkImage(_foundMember!['avatar_url']),
                           ),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               _foundMember!['display_name'],
                               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                             ),
                             Text(
                               'รหัสสมาชิก: ${_foundMember!['member_id']}',
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

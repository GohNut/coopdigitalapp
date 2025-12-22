import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/kyc_provider.dart';

class KYCStep2BankScreen extends ConsumerStatefulWidget {
  const KYCStep2BankScreen({super.key});

  @override
  ConsumerState<KYCStep2BankScreen> createState() => _KYCStep2BankScreenState();
}

class _KYCStep2BankScreenState extends ConsumerState<KYCStep2BankScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  
  String? _selectedBankId;
  String? _selectedBankName;
  XFile? _bankBookImage;
  Uint8List? _imageBytes;
  
  List<Map<String, dynamic>> _banks = [];
  bool _isLoadingBanks = true;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    try {
      final jsonString = await rootBundle.loadString('assets/bank_logos/banks-logo.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<Map<String, dynamic>> loadedBanks = [];
      jsonData.forEach((key, value) {
        // Skip PromptPay and TrueMoney
        if (key != 'PromptPay' && key != 'TrueMoney') {
          loadedBanks.add({
            'id': key,
            'name': value['name'] ?? key,
            'icon': 'assets/bank_logos/$key.png',
          });
        }
      });
      // Sort: KTB first, then alphabetically by id
      loadedBanks.sort((a, b) {
        if (a['id'] == 'KTB') return -1;
        if (b['id'] == 'KTB') return 1;
        return (a['id'] as String).compareTo(b['id'] as String);
      });
      if (mounted) {
        setState(() {
          _banks = loadedBanks;
          _isLoadingBanks = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading banks: $e');
      if (mounted) {
        setState(() => _isLoadingBanks = false);
      }
    }
  }

  void _showBankSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BankSelectorSheet(
        banks: _banks,
        selectedBank: _selectedBankId,
        onSelect: (bankId, bankName) {
          setState(() {
            _selectedBankId = bankId;
            _selectedBankName = bankName;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _bankBookImage = image;
        _imageBytes = bytes;
      });
    }
  }

  void _nextStep() {
    if (_formKey.currentState!.validate() && _bankBookImage != null && _selectedBankId != null) {
      ref.read(kycProvider.notifier).setBankInfo(
        _selectedBankId!,
        _accountController.text,
        _bankBookImage!,
      );
      context.push('/kyc/step3');
    } else if (_selectedBankId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกธนาคาร')),
      );
    } else if (_bankBookImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาถ่ายรูปหน้าสมุดบัญชี')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลบัญชีธนาคาร'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ระบุบัญชีสำหรับรับเงินปันผล', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // Bank Selection
              const Text('ธนาคาร', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _isLoadingBanks
                  ? const Center(child: CircularProgressIndicator())
                  : InkWell(
                      onTap: () => _showBankSelector(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _selectedBankId != null ? AppColors.primary : AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            if (_selectedBankId != null) ...[
                              Image.asset(
                                'assets/bank_logos/$_selectedBankId.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance, color: Colors.grey, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedBankName ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      _selectedBankId!,
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const Icon(LucideIcons.landmark, color: Colors.grey),
                              const SizedBox(width: 12),
                              const Expanded(child: Text('เลือกธนาคาร', style: TextStyle(color: Colors.grey))),
                            ],
                            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
              
              const SizedBox(height: 24),
              
              // Account Number
              const Text('เลขที่บัญชี', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(
                  hintText: 'xxx-x-xxxxx-x',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(LucideIcons.creditCard),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'กรุณาระบุเลขที่บัญชี' : null,
              ),
              const SizedBox(height: 32),
              
              const Text('รูปถ่ายหน้าสมุดบัญชี', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: _imageBytes != null ? AppColors.primary : Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(LucideIcons.camera, size: 32, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text('แตะเพื่อถ่ายรูป', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                ),
              ),
              if (_bankBookImage != null)
                Center(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(LucideIcons.refreshCcw),
                    label: const Text('ถ่ายใหม่'),
                  ),
                ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ถัดไป', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bank selector modal with search (same as withdrawal screen)
class _BankSelectorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> banks;
  final String? selectedBank;
  final Function(String id, String name) onSelect;

  const _BankSelectorSheet({
    required this.banks,
    required this.selectedBank,
    required this.onSelect,
  });

  @override
  State<_BankSelectorSheet> createState() => _BankSelectorSheetState();
}

class _BankSelectorSheetState extends State<_BankSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _filteredBanks = [];

  @override
  void initState() {
    super.initState();
    _filteredBanks = widget.banks;
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterBanks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = widget.banks;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredBanks = widget.banks.where((bank) {
          final name = (bank['name'] as String).toLowerCase();
          final id = (bank['id'] as String).toLowerCase();
          return name.contains(lowerQuery) || id.contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'เลือกธนาคาร',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _filterBanks,
              decoration: InputDecoration(
                hintText: _searchFocusNode.hasFocus ? null : 'ค้นหาธนาคาร...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Bank List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBanks.length,
              itemBuilder: (context, index) {
                final bank = _filteredBanks[index];
                final isSelected = widget.selectedBank == bank['id'];
                return ListTile(
                  leading: Image.asset(
                    bank['icon'] as String,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance, color: Colors.grey, size: 20),
                    ),
                  ),
                  title: Text(bank['name'] as String),
                  subtitle: Text(bank['id'] as String, style: TextStyle(color: Colors.grey[600])),
                  trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () => widget.onSelect(bank['id'] as String, bank['name'] as String),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

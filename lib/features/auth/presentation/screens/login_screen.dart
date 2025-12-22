import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dynamic_deposit_api.dart';
import '../../domain/user_role.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../payment/data/payment_providers.dart'; // Added import
import '../../../home/presentation/providers/profile_image_provider.dart';
import '../../../../core/providers/token_provider.dart';
import '../../../../core/utils/external_navigation.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idCardController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idCardFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _idCardFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _idCardController.dispose();
    _passwordController.dispose();
    _idCardFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => ExternalNavigation.backToILife(),
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          tooltip: 'กลับไป iLife',
        ),
        title: const Text(
          'กลับไป iLife',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.landmark,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'เข้าสู่ระบบสหกรณ์',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ระบบสหกรณ์ รสพ. Digital',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 48),

              // ID Card Input
              TextFormField(
                controller: _idCardController,
                focusNode: _idCardFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 13,
                decoration: InputDecoration(
                  labelText: _idCardFocusNode.hasFocus ? null : 'เลขบัตรประชาชน',
                  hintText: _idCardFocusNode.hasFocus ? null : 'กรอกเลข 13 หลัก',
                  prefixIcon: const Icon(LucideIcons.creditCard),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Password Input
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: _passwordFocusNode.hasFocus ? null : 'รหัสผ่าน',
                  hintText: _passwordFocusNode.hasFocus ? null : 'กรอกรหัสผ่าน (สำหรับสมาชิกใหม่)',
                  prefixIcon: const Icon(LucideIcons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ปุ่มกลับไป iLife (ถ้ามี token)
              if (ref.watch(tokenProvider) != null) ...[
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => ExternalNavigation.backToILife(),
                    icon: const Icon(LucideIcons.arrowLeftCircle, size: 20),
                    label: const Text('กลับไปยังแอป iLife'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Login Button
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleLogin,
                  icon: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.logIn),
                  label: Text(_isLoading ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Register Button
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final idCard = _idCardController.text.trim();
    final password = _passwordController.text.trim();
    
    if (idCard.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเลขบัตรประชาชนให้ครบ 13 หลัก')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call API to check member
      final memberData = await DynamicDepositApiService.getMember(idCard);
      
      if (!mounted) return;

      if (memberData != null) {
        // Check if member has password
        final storedPassword = memberData['password'] as String?;
        
        if (storedPassword != null && storedPassword.isNotEmpty) {
          // New member with password - validate password
          if (password.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('กรุณากรอกรหัสผ่าน'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
          
          if (password != storedPassword) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('รหัสผ่านไม่ถูกต้อง'),
                backgroundColor: Colors.redAccent,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
        }
        // If storedPassword is null/empty, it's an old member - allow login without password
        
        // โหลดรูปโปรไฟล์
        String? profileImageUrl;
        try {
          final imageData = await DynamicDepositApiService.getProfileImageUrl(idCard);
          if (imageData != null) {
            profileImageUrl = imageData['url'];
          }
        } catch (e) {
          debugPrint('Failed to load profile image: $e');
          // ไม่ต้อง error ถ้าไม่มีรูป
        }
        
        // Determine Role
        final roleStr = memberData['role'] as String? ?? 'member';
        UserRole userRole = UserRole.member;
        if (roleStr == 'officer') {
          userRole = UserRole.officer;
        } else if (roleStr == 'approver') {
          userRole = UserRole.approver;
        }

        // Login successful - Update CurrentUser
        await CurrentUser.setUser(
          newName: memberData['name_th'] ?? 'สมาชิกสหกรณ์',
          newId: idCard, // Use ID Card as ID
          newRole: userRole,
          newIsMember: true,
          newPin: memberData['pin'], // Load PIN from API
          newProfileImageUrl: profileImageUrl, // โหลดรูปโปรไฟล์
          newKycStatus: memberData['kyc_status'], // โหลดสถานะ KYC
        );

        // Migration Check: If PIN is missing, set default '123456'
        if (memberData['pin'] == null) {
           // Auto-update to default PIN
           try {
             await DynamicDepositApiService.updateMember(
               memberId: idCard,
               data: {'pin': '123456'},
             );
             // Update local user state
             CurrentUser.pin = '123456';
             await CurrentUser.saveUser(); // Persist the new PIN
             debugPrint('Auto-migrated user PIN to 123456');
           } catch (e) {
             debugPrint('Failed to migrate PIN: $e');
             // Proceed anyway, maybe ask user later? For now, just let them in.
           }
        }

        // Invalidate providers to ensure data is fresh for the new user
        ref.invalidate(depositAccountsAsyncProvider);
        ref.invalidate(totalDepositBalanceAsyncProvider);
        ref.invalidate(paymentSourcesProvider); // Added: Invalidate payment sources
        
        // Initialize profile image provider with the loaded URL
        if (profileImageUrl != null) {
          ref.read(profileImageUrlProvider.notifier).setImageUrl(profileImageUrl);
        }

        context.go('/home');
      } else {
        // Not Found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบข้อมูลสมาชิก กรุณาสมัครสมาชิกก่อนเข้าใช้งาน'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

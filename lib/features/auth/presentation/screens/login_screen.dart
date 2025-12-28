import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_text.dart';
import '../../../../core/utils/responsive_spacing.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/dynamic_deposit_api.dart';
import '../../domain/user_role.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../payment/data/payment_providers.dart';
import '../../../home/presentation/providers/profile_image_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../../core/providers/token_provider.dart';
import '../../../../core/utils/external_navigation.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  late Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
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

  /// Helper method to create TextFormField with locked zoom
  Widget _buildLockedTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType? keyboardType,
    int? maxLength,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
  }) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLength: maxLength,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: focusNode.hasFocus ? null : labelText,
          hintText: focusNode.hasFocus ? null : hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
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
          contentPadding: context.formFieldPadding,
        ),
      ),
    );
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
        title: Text(
          'กลับไป iLife',
          style: context.headlineMediumText.copyWith(
            color: AppColors.primary,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.screenPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - context.safeArea.top - context.safeArea.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo or Icon
                      Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/pic/logoCoop.jpg',
                            width: context.isSmallScreen ? 100 : 130,
                            height: context.isSmallScreen ? 100 : 130,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      context.spacerM,
                      
                      ResponsiveTextWidget(
                        text: 'เข้าสู่ระบบสหกรณ์',
                        textAlign: TextAlign.center,
                        style: context.displayLargeText.copyWith(
                          color: Colors.black87,
                        ),
                      ),
                      context.spacerS,
                      
                      ResponsiveTextWidget(
                        text: 'ระบบสหกรณ์ รสพ. ดิจิตอล',
                        textAlign: TextAlign.center,
                        style: context.bodyLargeText.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      
                      context.spacerL,

                      // ID Card Input
                      _buildLockedTextFormField(
                        controller: _idCardController,
                        focusNode: _idCardFocusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 13,
                        labelText: 'เลขบัตรประชาชน',
                        hintText: 'กรอกเลข 13 หลัก',
                        prefixIcon: const Icon(LucideIcons.creditCard),
                      ),
                      
                      context.spacerM,

                      // Password Input
                      _buildLockedTextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_isPasswordVisible,
                        labelText: 'รหัสผ่าน',
                        hintText: 'กรอกรหัสผ่าน (สำหรับสมาชิกใหม่)',
                        prefixIcon: const Icon(LucideIcons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      
                      context.spacerL,

                      // Login Button
                      SizedBox(
                        height: context.isSmallScreen ? 48 : 54,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleLogin,
                          icon: _isLoading
                            ? SizedBox(
                                width: context.isSmallScreen ? 20 : 24,
                                height: context.isSmallScreen ? 20 : 24,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                              )
                            : const Icon(LucideIcons.logIn),
                          label: ResponsiveTextWidget(
                            text: _isLoading ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบ',
                            style: context.buttonTextStyle,
                          ),
                          style: AppTheme.responsiveButtonStyle(context),
                        ),
                      ),
                      
                      context.spacerM,

                      // Register Button
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: ResponsiveTextWidget(
                          text: 'ยังไม่มีบัญชี? สมัครสมาชิก',
                          style: context.bodyLargeText.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: context.screenPadding,
          child: FutureBuilder<PackageInfo>(
            future: _packageInfoFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ResponsiveTextWidget(
                  text: 'Version ${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})',
                  textAlign: TextAlign.center,
                  style: context.bodyMediumText.copyWith(
                    color: Colors.grey.shade500,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final idCard = _idCardController.text.trim();
    final password = _passwordController.text.trim();
    
    print('🔐 [LOGIN] Attempting login with ID: $idCard');
    
    if (idCard.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเลขบัตรประชาชนให้ครบ 13 หลัก')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call API to check member
      print('🔐 [LOGIN] Calling getMember API...');
      final memberData = await DynamicDepositApiService.getMember(idCard);
      
      print('🔐 [LOGIN] Member data received: ${memberData != null ? "Found" : "Not found"}');
      if (memberData != null) {
        print('🔐 [LOGIN] Member data: $memberData');
      }
      
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
        ref.invalidate(paymentSourcesProvider);
        ref.invalidate(notificationProvider); // Ensure notifications are loaded for new user
        
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
      print('❌ [LOGIN] Error occurred: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

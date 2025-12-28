import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/token_provider.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/notification/presentation/screens/notification_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/main_layout_screen.dart';
import '../../features/home/presentation/screens/profile_screen.dart';
import '../../features/wallet/presentation/screens/account_book_screen.dart';
import '../../features/deposit/presentation/screens/deposit_account_list_screen.dart';
import '../../features/deposit/presentation/screens/deposit_account_detail_screen.dart';

import '../../features/deposit/presentation/screens/create_account_screen.dart';
import '../../features/deposit/presentation/screens/officer_deposit_check_screen.dart';
import '../../features/wallet/presentation/screens/officer_withdrawal_check_screen.dart';
import '../../features/loan/presentation/screens/loan_products_screen.dart';
import '../../features/loan/presentation/screens/loan_application_screen.dart';
import '../../features/wallet/presentation/screens/top_up_amount_screen.dart';
import '../../features/wallet/presentation/screens/top_up_qr_screen.dart';
import '../../features/wallet/presentation/screens/withdraw_input_screen.dart';
import '../../features/wallet/presentation/screens/withdraw_review_screen.dart';
import '../../features/transfer/presentation/screens/transfer_search_screen.dart';
import '../../features/transfer/presentation/screens/transfer_input_screen.dart';
import '../../features/transfer/presentation/screens/transfer_success_screen.dart';
import '../../features/transfer/presentation/screens/transfer_own_accounts_screen.dart';
import '../../features/payment/presentation/screens/scan_screen.dart';
import '../../features/payment/presentation/screens/payment_input_screen.dart';
import '../../features/payment/presentation/screens/payment_success_screen.dart';
import '../../features/payment/presentation/screens/payment_source_selection_screen.dart';
import '../../features/loan/presentation/screens/loan_dashboard_screen.dart';
import '../../features/loan/presentation/screens/loan_calculator_screen.dart';
import '../../features/loan/presentation/screens/loan_info_screen.dart';
import '../../features/loan/presentation/screens/loan_document_screen.dart';
import '../../features/loan/presentation/screens/loan_review_screen.dart';
import '../../features/auth/presentation/screens/pin_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register/register_wizard_screen.dart';
import '../../features/loan/presentation/screens/loan_success_screen.dart';
import '../../features/loan/presentation/screens/loan_tracking_screen.dart';
import '../../features/loan/presentation/screens/loan_contract_detail_screen.dart';
import '../../features/loan/presentation/screens/loan_payment_history_screen.dart';
import '../../features/loan/presentation/screens/loan_payment_screen.dart';
import '../../features/loan/presentation/screens/loan_payment_success_screen.dart';
import '../../features/loan/domain/loan_request_args.dart';
import '../../features/share/presentation/screens/share_dashboard_screen.dart';
import '../../features/share/presentation/screens/buy_extra_share_screen.dart';
import '../../features/share/presentation/screens/share_payment_method_screen.dart';
import '../../features/share/presentation/screens/share_confirmation_screen.dart';
import '../../features/share/presentation/screens/buy_share_success_screen.dart';
import '../../features/share/presentation/screens/share_qr_payment_screen.dart';

import '../../features/share/presentation/screens/change_share_subscription_screen.dart';
import '../../features/share/presentation/screens/share_history_screen.dart';
import '../../features/share/presentation/screens/dividend_detail_screen.dart';
import '../../features/share/presentation/screens/dividend_history_screen.dart';
import '../../features/share/presentation/screens/dividend_request_screen.dart';
import '../../features/loan/presentation/screens/loan_products_management_screen.dart';
import '../../features/loan/presentation/screens/loan_product_form_screen.dart';
import '../../features/loan/presentation/screens/additional_document_review_screen.dart';
import '../../features/loan/domain/loan_product_model.dart';
import '../../features/kyc/presentation/screens/kyc_intro_screen.dart';
import '../../features/kyc/presentation/screens/kyc_step1_idcard_screen.dart';
import '../../features/kyc/presentation/screens/kyc_step2_bank_screen.dart';
import '../../features/kyc/presentation/screens/kyc_step3_selfie_screen.dart';
import '../../features/kyc/presentation/screens/kyc_review_screen.dart';
import '../../features/kyc/presentation/screens/officer_kyc_list_screen.dart';
import '../../features/kyc/presentation/screens/officer_kyc_detail_screen.dart';
import '../../features/share/presentation/screens/officer_share_type_management_screen.dart';
import '../../features/loan/presentation/screens/officer_loan_detail_screen.dart';
import '../../features/loan/domain/loan_application_model.dart';
import '../../features/wallet/presentation/screens/officer_withdrawal_detail_screen.dart';
import '../../features/deposit/presentation/screens/officer_deposit_detail_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: CurrentUser.id.isNotEmpty ? '/home' : '/login',
    redirect: (context, state) {
      final bool loggedIn = CurrentUser.id.isNotEmpty;
      final bool isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // ถ้ายังไม่ได้ล็อกอิน และไม่ได้อยู่ที่หน้า login/register ให้ไปหน้า login
      if (!loggedIn && !isLoggingIn) {
        return '/login';
      }

      // ถ้าล็อกอินแล้ว แต่อยู่ที่หน้า login/register ให้ไปหน้า home
      if (loggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterWizardScreen(),
      ),
      GoRoute(
        path: '/notifications', // Changed from '/notification' to match standard plural
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notification',
        redirect: (context, state) => '/notifications',
      ),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayoutScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Account Book (Left)
          StatefulShellBranch(
            navigatorKey: shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/account-book',
                builder: (context, state) => const AccountBookScreen(),
              ),
            ],
          ),
          // Branch 1: Home / iLife (Right)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                redirect: (context, state) {
                  // ดักจับ token จาก query parameter
                  final token = state.uri.queryParameters['token'];
                  if (token != null && token.isNotEmpty) {
                    // บันทึก token ลง provider
                    final container = ProviderScope.containerOf(context);
                    container.read(tokenProvider.notifier).setToken(token);
                  }
                  return null; // ดำเนินการต่อไปยังหน้า home ตามปกติ
                },
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
        ],
      ),
      // Deposit (เงินฝาก) Routes
      GoRoute(
        path: '/deposit',
        builder: (context, state) => const DepositAccountListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateAccountScreen(),
          ),
          GoRoute(
            path: ':accountId',
            builder: (context, state) {
              final accountId = state.pathParameters['accountId'] ?? '';
              return DepositAccountDetailScreen(accountId: accountId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/wallet',
        redirect: (context, state) {
          // Only redirect if accessing /wallet directly, not sub-routes
          final path = state.uri.path;
          if (path == '/wallet' || path == '/wallet/') {
            return '/home';
          }
          return null; // Allow sub-routes to proceed
        },
        routes: [
           GoRoute(
            path: 'topup',
            builder: (context, state) => const TopUpAmountScreen(),
            routes: [
              GoRoute(
                path: 'qr',
                builder: (context, state) {
                  final params = state.extra as Map<String, dynamic>? ?? {'amount': 0.0, 'accountId': ''};
                  return TopUpQrScreen(params: params);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'withdraw',
             builder: (context, state) => const WithdrawInputScreen(),
             routes: [
               GoRoute(
                 path: 'confirm',
                  builder: (context, state) {
                     if (state.extra is! Map<String, dynamic>) return const WithdrawInputScreen();
                     final args = state.extra as Map<String, dynamic>;
                     return WithdrawReviewScreen(args: args);
                  },
               ),
             ]
          ),
        ],
      ),
      GoRoute(
        path: '/transfer',
        builder: (context, state) => const TransferSearchScreen(),
        routes: [
          GoRoute(
            path: 'input',
            builder: (context, state) {
              if (state.extra is! Map<String, dynamic>) return const TransferSearchScreen();
              final account = state.extra as Map<String, dynamic>;
              return TransferInputScreen(account: account);
            },
          ),
          GoRoute(
            path: 'own',
            builder: (context, state) => const TransferOwnAccountsScreen(),
          ),
          GoRoute(
            path: 'success',
            builder: (context, state) {
              if (state.extra is! Map<String, dynamic>) return const TransferSearchScreen();
              final args = state.extra as Map<String, dynamic>;
              return TransferSuccessScreen(args: args);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/payment',
        redirect: (context, state) {
          // Only redirect if accessing /payment directly, not sub-routes
          final path = state.uri.path;
          if (path == '/payment' || path == '/payment/') {
            return '/payment/source';
          }
          return null; // Allow sub-routes to proceed
        },
        routes: [
           GoRoute(
            path: 'source',
            builder: (context, state) => const PaymentSourceSelectionScreen(),
          ),
           GoRoute(
            path: 'input',
            builder: (context, state) {
              if (state.extra is! Map<String, dynamic>) return const PaymentSourceSelectionScreen();
              final args = state.extra as Map<String, dynamic>;
              return PaymentInputScreen(args: args);
            },
          ),
           GoRoute(
            path: 'success',
            builder: (context, state) {
              if (state.extra is! Map<String, dynamic>) return const PaymentSourceSelectionScreen();
              final args = state.extra as Map<String, dynamic>;
              return PaymentSuccessScreen(args: args);
            },
          ),
        ]
      ),
      GoRoute(
        path: '/pin',
        builder: (context, state) => const PinVerificationScreen(),
      ),
      GoRoute(
        path: '/loan',
        builder: (context, state) => const LoanDashboardScreen(),
        routes: [
           GoRoute(
            path: 'products',
            builder: (context, state) => const LoanProductsScreen(),
          ),
           GoRoute(
            path: 'calculate/:productId',
            builder: (context, state) {
              final productId = state.pathParameters['productId'] ?? '';
              return LoanCalculatorScreen(productId: productId);
            },
          ),
          GoRoute(
            path: 'info',
            builder: (context, state) {
              if (state.extra is! LoanRequestArgs) return const LoanDashboardScreen();
              final args = state.extra as LoanRequestArgs;
              return LoanInfoScreen(args: args);
            },
          ),
          GoRoute(
            path: 'document',
            builder: (context, state) {
              if (state.extra is! LoanRequestArgs) return const LoanDashboardScreen();
              final args = state.extra as LoanRequestArgs;
              return LoanDocumentScreen(args: args);
            },
          ),
          GoRoute(
            path: 'review',
            builder: (context, state) {
              if (state.extra is! LoanRequestArgs) return const LoanDashboardScreen();
              final args = state.extra as LoanRequestArgs;
              return LoanReviewScreen(args: args);
            },
          ),
          GoRoute(
            path: 'pin',
            builder: (context, state) => const PinVerificationScreen(),
          ),
          GoRoute(
            path: 'success',
            builder: (context, state) => const LoanSuccessScreen(),
          ),
          GoRoute(
            path: 'tracking',
            builder: (context, state) => const LoanTrackingScreen(),
          ),
          GoRoute(
            path: 'contract/:id',
            builder: (context, state) {
               final id = state.pathParameters['id'] ?? '';
               return LoanContractDetailScreen(contractId: id);
            },
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const LoanPaymentHistoryScreen(),
          ),
          GoRoute(
            path: 'payment/success',
            builder: (context, state) {
               if (state.extra is! Map<String, dynamic>) return const LoanDashboardScreen();
               final args = state.extra as Map<String, dynamic>;
               return LoanPaymentSuccessScreen(args: args);
            },
          ),
          GoRoute(
            path: 'payment/:applicationId',
            builder: (context, state) {
               final applicationId = state.pathParameters['applicationId'] ?? '';
               return LoanPaymentScreen(applicationId: applicationId);
            },
          ),
          GoRoute(
            path: 'additional-document-review',
            builder: (context, state) {
               final args = state.extra as AdditionalDocumentArgs;
               return AdditionalDocumentReviewScreen(args: args);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/loan/apply/:id',
        builder: (context, state) {
           final id = state.pathParameters['id'] ?? '';
           return LoanApplicationScreen(productId: id);
        },
      ),
      // Loan Products Management (Officer only)
      GoRoute(
        path: '/loan-products-management',
        builder: (context, state) => const LoanProductsManagementScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const LoanProductFormScreen(),
          ),
          GoRoute(
            path: 'edit/:productId',
            builder: (context, state) {
              final product = state.extra as LoanProduct;
              return LoanProductFormScreen(product: product);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/share',
        builder: (context, state) => const ShareDashboardScreen(),
        routes: [
          GoRoute(
            path: 'buy',
            builder: (context, state) => const BuyExtraShareScreen(),
            routes: [
              GoRoute(
                path: 'payment',
                builder: (context, state) {
                  if (state.extra is! Map<String, dynamic>) return const BuyExtraShareScreen();
                  final args = state.extra as Map<String, dynamic>;
                  return SharePaymentMethodScreen(args: args);
                },
              ),
              GoRoute(
                path: 'confirm',
                builder: (context, state) {
                  if (state.extra is! Map<String, dynamic>) return const BuyExtraShareScreen();
                  final args = state.extra as Map<String, dynamic>;
                  return ShareConfirmationScreen(args: args);
                },
              ),
              GoRoute(
                path: 'qr',
                builder: (context, state) {
                  if (state.extra is! Map<String, dynamic>) return const BuyExtraShareScreen();
                  final args = state.extra as Map<String, dynamic>;
                  return ShareQrPaymentScreen(args: args);
                },
              ),
              GoRoute(
                path: 'success',
                builder: (context, state) => const BuyShareSuccessScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'change',
            builder: (context, state) => const ChangeShareSubscriptionScreen(),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const ShareHistoryScreen(),
          ),
          GoRoute(
            path: 'dividend',
            builder: (context, state) => const DividendDetailScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => const DividendHistoryScreen(),
              ),
              GoRoute(
                path: 'request',
                builder: (context, state) {
                  if (state.extra is! Map<String, dynamic>) return const DividendDetailScreen();
                  final args = state.extra as Map<String, dynamic>;
                  return DividendRequestScreen(args: args);
                },
              ),
            ],
          ),
        ],
      ),

      // Officer Routes
      GoRoute(
        path: '/officer/deposit-check',
        builder: (context, state) => const OfficerDepositCheckScreen(),
      ),
      GoRoute(
        path: '/officer/withdrawal-check',
        builder: (context, state) => const OfficerWithdrawalCheckScreen(),
      ),
      GoRoute(
        path: '/officer/kyc-check',
        builder: (context, state) => const OfficerKYCListScreen(),
      ),
      GoRoute(
        path: '/officer/kyc-detail/:memberId',
        builder: (context, state) {
          final memberId = state.pathParameters['memberId']!;
          return OfficerKYCDetailScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: '/officer/loan-detail/:applicationId',
        builder: (context, state) {
          final appId = state.pathParameters['applicationId']!;
          // Using state.extra if available, otherwise we might need a way to fetch by ID
          // For now, let's assume detail screen can fetch if we pass ID or we update it.
          // Adjusting OfficerLoanDetailScreen to support ID might be better for deep links.
          // But for now let's see if we can pass via extra and if not, we need a fetch logic.
          if (state.extra is LoanApplication) {
            return OfficerLoanDetailScreen(application: state.extra as LoanApplication);
          }
          // Redirect to check screen if no data, OR ideally detail screen handles it
          return const LoanDashboardScreen(); // Fallback
        },
      ),
      GoRoute(
        path: '/officer/withdrawal-detail',
        builder: (context, state) {
           if (state.extra is! Map<String, dynamic>) {
             return const OfficerWithdrawalCheckScreen();
           }
           final withdrawal = state.extra as Map<String, dynamic>;
           return OfficerWithdrawalDetailScreen(withdrawal: withdrawal);
        },
      ),
      GoRoute(
        path: '/officer/deposit-detail',
        builder: (context, state) {
           if (state.extra is! Map<String, dynamic>) {
             return const OfficerDepositCheckScreen();
           }
           final deposit = state.extra as Map<String, dynamic>;
           return OfficerDepositDetailScreen(deposit: deposit);
        },
      ),
      GoRoute(
        path: '/officer/share-type',
        builder: (context, state) => const OfficerShareTypeManagementScreen(),
      ),

      // KYC Routes
      GoRoute(
        path: '/kyc',
        builder: (context, state) => const KYCIntroScreen(),
        routes: [
          GoRoute(
            path: 'step1',
            builder: (context, state) => const KYCStep1IDCardScreen(),
          ),
          GoRoute(
            path: 'step2',
            builder: (context, state) => const KYCStep2BankScreen(),
          ),
          GoRoute(
            path: 'step3',
            builder: (context, state) => const KYCStep3SelfieScreen(),
          ),
          GoRoute(
            path: 'review',
            builder: (context, state) => const KYCReviewScreen(),
          ),
        ],
      ),
    ],
  );
});

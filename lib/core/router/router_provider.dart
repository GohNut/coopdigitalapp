import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/main_layout_screen.dart';
import '../../features/wallet/presentation/screens/account_book_screen.dart';
import '../../features/deposit/presentation/screens/deposit_account_list_screen.dart';
import '../../features/deposit/presentation/screens/deposit_account_detail_screen.dart';
import '../../features/loan/presentation/screens/loan_products_screen.dart';
import '../../features/loan/presentation/screens/loan_application_screen.dart';
import '../../features/wallet/presentation/screens/top_up_amount_screen.dart';
import '../../features/wallet/presentation/screens/top_up_qr_screen.dart';
import '../../features/wallet/presentation/screens/withdraw_input_screen.dart';
import '../../features/wallet/presentation/screens/withdraw_review_screen.dart';
import '../../features/transfer/presentation/screens/transfer_search_screen.dart';
import '../../features/transfer/presentation/screens/transfer_input_screen.dart';
import '../../features/transfer/presentation/screens/transfer_success_screen.dart';
import '../../features/payment/presentation/screens/scan_screen.dart';
import '../../features/payment/presentation/screens/payment_input_screen.dart';
import '../../features/payment/presentation/screens/payment_success_screen.dart';
import '../../features/loan/presentation/screens/loan_dashboard_screen.dart';
import '../../features/loan/presentation/screens/loan_calculator_screen.dart';
import '../../features/loan/presentation/screens/loan_info_screen.dart';
import '../../features/loan/presentation/screens/loan_document_screen.dart';
import '../../features/loan/presentation/screens/loan_review_screen.dart';
import '../../features/auth/presentation/screens/pin_verification_screen.dart';
import '../../features/loan/presentation/screens/loan_success_screen.dart';
import '../../features/loan/presentation/screens/loan_tracking_screen.dart';
import '../../features/loan/presentation/screens/loan_contract_detail_screen.dart';
import '../../features/loan/presentation/screens/loan_payment_history_screen.dart';
import '../../features/loan/domain/loan_request_args.dart';
import '../../features/share/presentation/screens/share_dashboard_screen.dart';
import '../../features/share/presentation/screens/buy_extra_share_screen.dart';
import '../../features/share/presentation/screens/share_payment_method_screen.dart';
import '../../features/share/presentation/screens/share_confirmation_screen.dart';
import '../../features/share/presentation/screens/buy_share_success_screen.dart';
import '../../features/share/presentation/screens/sell_share_screen.dart';
import '../../features/share/presentation/screens/sell_share_success_screen.dart';
import '../../features/share/presentation/screens/change_share_subscription_screen.dart';
import '../../features/share/presentation/screens/share_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    routes: [
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
                  final amount = state.extra as double? ?? 0.0;
                  return TopUpQrScreen(amount: amount);
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
              final member = state.extra as Map<String, dynamic>;
              return TransferInputScreen(member: member);
            },
          ),
          GoRoute(
            path: 'success',
            builder: (context, state) {
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
            return '/scan';
          }
          return null; // Allow sub-routes to proceed
        },
        routes: [
           GoRoute(
            path: 'input',
            builder: (context, state) {
              final merchant = state.extra as Map<String, dynamic>;
              return PaymentInputScreen(merchant: merchant);
            },
          ),
           GoRoute(
            path: 'success',
            builder: (context, state) {
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
              final args = state.extra as LoanRequestArgs;
              return LoanInfoScreen(args: args);
            },
          ),
          GoRoute(
            path: 'document',
            builder: (context, state) {
              final args = state.extra as LoanRequestArgs;
              return LoanDocumentScreen(args: args);
            },
          ),
          GoRoute(
            path: 'review',
            builder: (context, state) {
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
        ],
      ),
      GoRoute(
        path: '/loan/apply/:id',
        builder: (context, state) {
           final id = state.pathParameters['id'] ?? '';
           return LoanApplicationScreen(productId: id);
        },
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
                final args = state.extra as Map<String, dynamic>;
                return SharePaymentMethodScreen(args: args);
              },
            ),
            GoRoute(
              path: 'confirm',
              builder: (context, state) {
                final args = state.extra as Map<String, dynamic>;
                return ShareConfirmationScreen(args: args);
              },
            ),
            GoRoute(
              path: 'success',
              builder: (context, state) => const BuyShareSuccessScreen(),
            ),
          ]
        ),
        GoRoute(
          path: 'sell',
          builder: (context, state) => const SellShareScreen(),
          routes: [
             GoRoute(
               path: 'success',
               builder: (context, state) => const SellShareSuccessScreen(),
             ),
          ]
        ),
           GoRoute(
            path: 'change',
            builder: (context, state) => const ChangeShareSubscriptionScreen(),
          ),
           GoRoute(
            path: 'history',
            builder: (context, state) => const ShareHistoryScreen(),
          ),
        ],
      ),
    ],
  );
});

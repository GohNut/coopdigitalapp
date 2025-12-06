import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/main_layout_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/main_layout_screen.dart';
import '../../features/loan/presentation/screens/loan_products_screen.dart';
import '../../features/loan/presentation/screens/loan_application_screen.dart';
import '../../features/loan/presentation/screens/loan_dashboard_screen.dart';
import '../../features/loan/presentation/screens/loan_calculator_screen.dart';
import '../../features/loan/presentation/screens/loan_review_screen.dart';
import '../../features/loan/presentation/screens/pin_verification_screen.dart';
import '../../features/loan/presentation/screens/loan_success_screen.dart';
import '../../features/loan/presentation/screens/loan_tracking_screen.dart';
import '../../features/loan/presentation/screens/loan_contract_detail_screen.dart';
import '../../features/loan/presentation/screens/loan_payment_history_screen.dart';
import '../../features/loan/domain/loan_request_args.dart';

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
          StatefulShellBranch(
            navigatorKey: shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          
          // Loan Tab (Hidden or integrated) - For now let's access it via Home
        ],
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
    ],
  );
});

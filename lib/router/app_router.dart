import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/counsellor_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registration_verification_screen.dart';
import '../screens/auth/pending_verification_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/consultation/audio_call_screen.dart';
import '../screens/consultation/video_call_screen.dart';
import '../screens/wallet/wallet_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final bool isAuth = authProvider.isAuthenticated;
        final bool isLoading = authProvider.isLoading;
        final CounsellorModel? counsellor = authProvider.counsellor;

        final String loc = state.matchedLocation;

        if (isLoading) return null;

        // If not logged in, force to login screen
        if (!isAuth) {
          return loc == '/login' ? null : '/login';
        }

        // If authenticated but no counsellor profile document exists yet
        if (counsellor == null) {
          return loc == '/registration-verification' ? null : '/registration-verification';
        }

        // If verification is pending or rejected
        if (counsellor.verificationStatus == VerificationStatus.pending ||
            counsellor.verificationStatus == VerificationStatus.rejected) {
          return loc == '/pending-verification' ? null : '/pending-verification';
        }

        // If approved, block auth / pending screens and redirect to dashboard
        if (counsellor.verificationStatus == VerificationStatus.approved) {
          if (loc == '/login' ||
              loc == '/registration-verification' ||
              loc == '/pending-verification') {
            return '/dashboard';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/registration-verification',
          builder: (context, state) => const RegistrationVerificationScreen(),
        ),
        GoRoute(
          path: '/pending-verification',
          builder: (context, state) => const PendingVerificationScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/audio-call',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return AudioCallScreen(
              channelId: extra['channelId'] ?? 'demo_channel',
              clientName: extra['clientName'] ?? 'Client',
              agoraToken: extra['agoraToken'],
            );
          },
        ),
        GoRoute(
          path: '/video-call',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return VideoCallScreen(
              channelId: extra['channelId'] ?? 'demo_channel',
              clientName: extra['clientName'] ?? 'Client',
              agoraToken: extra['agoraToken'],
            );
          },
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const WalletScreen(),
        ),
      ],
    );
  }
}

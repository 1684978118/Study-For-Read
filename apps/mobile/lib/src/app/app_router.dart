import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/reader/presentation/reader_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/vocabulary/presentation/vocabulary_screen.dart';

GoRouter createAppRouter({
  required bool isSignedIn,
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute = path == '/sign-in' || path == '/register';

      if (!isSignedIn && !isAuthRoute) {
        return '/sign-in';
      }

      if (isSignedIn && (path == '/' || path == '/sign-in')) {
        return '/library';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => isSignedIn ? '/library' : '/sign-in',
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _HomeShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/vocabulary',
            builder: (context, state) => const VocabularyScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) => const ReaderScreen(),
      ),
    ],
  );
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(location),
        type: BottomNavigationBarType.fixed,
        onTap: (index) => context.go(_routes[index]),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style_outlined),
            activeIcon: Icon(Icons.style),
            label: 'Vocabulary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  static const _routes = [
    '/library',
    '/vocabulary',
    '/stats',
    '/settings',
  ];

  static int _selectedIndex(String location) {
    final index = _routes.indexWhere((route) => location.startsWith(route));
    return index < 0 ? 0 : index;
  }
}

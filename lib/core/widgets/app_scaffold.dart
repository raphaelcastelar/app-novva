import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes/route_names.dart';
import '../../app/theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.showBottomBar = true,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: child),
      bottomNavigationBar: showBottomBar ? const _BottomNav() : null,
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    return NavigationBar(
      selectedIndex: index,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      onDestinationSelected: (value) {
        switch (value) {
          case 0:
            context.go(RouteNames.dashboard);
          case 1:
            context.go(RouteNames.documents);
          case 2:
            context.go(RouteNames.obligations);
          case 3:
            context.go(RouteNames.settings);
        }
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início'),
        NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Docs'),
        NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Guias'),
        NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes'),
      ],
    );
  }

  int _indexFor(String location) {
    if (location.startsWith(RouteNames.documents)) return 1;
    if (location.startsWith(RouteNames.obligations)) return 2;
    if (location.startsWith(RouteNames.settings)) return 3;
    return 0;
  }
}

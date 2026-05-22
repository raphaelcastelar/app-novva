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
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBottomBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          title.isEmpty ? null : AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: child),
      floatingActionButton: floatingActionButton,
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
            context.go(RouteNames.invoices);
          case 4:
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
            icon: Icon(Icons.note_add_outlined),
            selectedIcon: Icon(Icons.note_add),
            label: 'Notas'),
        NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Mais'),
      ],
    );
  }

  int _indexFor(String location) {
    if (location.startsWith(RouteNames.documents)) return 1;
    if (location.startsWith(RouteNames.obligations)) return 2;
    if (location.startsWith(RouteNames.invoices)) return 3;
    if (location.startsWith(RouteNames.settings) ||
        location.startsWith(RouteNames.reports) ||
        location.startsWith(RouteNames.chat) ||
        location.startsWith(RouteNames.profile) ||
        location.startsWith(RouteNames.cnpjs) ||
        location.startsWith(RouteNames.notifications)) {
      return 4;
    }
    return 0;
  }
}

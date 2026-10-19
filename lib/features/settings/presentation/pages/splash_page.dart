import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _continue();
  }

  Future<void> _continue() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final biometrics = ref.read(biometricAuthServiceProvider);
    if (await biometrics.canUseForLogin()) {
      final authenticated =
          await ref.read(authControllerProvider.notifier).loginWithBiometrics();
      if (authenticated || !mounted) return;
    }
    if (mounted) context.go(RouteNames.loginCpf);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/firstpage.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

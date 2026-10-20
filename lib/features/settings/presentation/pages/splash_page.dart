import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/novva_logo.dart';

const _splashBackground = Color(0xFF031923);
const _splashSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarBrightness: Brightness.dark,
  statusBarIconBrightness: Brightness.light,
  systemStatusBarContrastEnforced: false,
);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _continue();
  }

  Future<void> _continue() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    context.go(RouteNames.loginCpf);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _splashSystemUiStyle,
      child: Scaffold(
        backgroundColor: _splashBackground,
        body: Center(
          child: RotationTransition(
            turns: _rotationController,
            child: const NovvaLogo(size: 92),
          ),
        ),
      ),
    );
  }
}

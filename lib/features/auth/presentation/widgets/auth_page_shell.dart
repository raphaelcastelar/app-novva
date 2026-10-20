import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const authBackground = Color(0xFF031923);
const authSurface = Color(0xFF102630);
const authBorder = Color(0xFF294652);
const authAccent = Color(0xFF35C8F5);
const authMuted = Color(0xFF9AAEB8);

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight =
                (constraints.maxHeight * 0.54).clamp(360.0, 500.0);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: heroHeight, child: const AuthCarousel()),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthCarousel extends StatefulWidget {
  const AuthCarousel({super.key});

  @override
  State<AuthCarousel> createState() => _AuthCarouselState();
}

class _AuthCarouselState extends State<AuthCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  static const _slides = [
    _AuthSlideData(
      photoDescription: 'Médica sorrindo no consultório',
      title: 'Gestão médica,',
      highlightedTitle: 'simplificada.',
      subtitle:
          'Cuidamos das suas finanças e contabilidade para você cuidar de vidas.',
      icon: Icons.medical_services_outlined,
    ),
    _AuthSlideData(
      photoDescription:
          'Médico revisando as finanças no notebook, no consultório',
      title: 'Suas finanças,',
      highlightedTitle: 'em um só lugar.',
      subtitle:
          'Acompanhe faturamento, notas fiscais e impostos direto pelo app.',
      icon: Icons.laptop_mac_outlined,
      calloutTitle: 'Nota fiscal emitida',
      calloutSubtitle: 'Enviada ao tomador',
    ),
    _AuthSlideData(
      photoDescription:
          'Médica sorrindo ao celular, entre um atendimento e outro',
      title: 'Seu assessor,',
      highlightedTitle: 'a um toque.',
      subtitle:
          'Fale com uma equipe que entende a rotina de quem cuida de vidas.',
      icon: Icons.phone_iphone_outlined,
      calloutTitle: 'Já sim! Enviei o PDF aqui para você.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => _AuthSlide(data: _slides[index]),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 20,
            child: Column(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo_mark.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Novva',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            bottom: 18,
            child: Row(
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: index == _page ? 24 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    color: index == _page ? Colors.white : authMuted,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthSlide extends StatelessWidget {
  const _AuthSlide({required this.data});

  final _AuthSlideData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF123541), Color(0xFF061C25)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 54,
            right: 54,
            top: 112,
            height: 112,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.025),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF5B8291),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(data.icon, color: authMuted, size: 24),
                  const SizedBox(height: 7),
                  Text(
                    data.photoDescription,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB5C4CB),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Imagem do carrossel',
                    style: TextStyle(color: authMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (data.calloutTitle != null)
            Positioned(
              right: 24,
              top: 236,
              child: _CarouselCallout(data: data),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  data.highlightedTitle,
                  style: const TextStyle(
                    color: Color(0xFFAEE7FF),
                    fontSize: 27,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselCallout extends StatelessWidget {
  const _CarouselCallout({required this.data});

  final _AuthSlideData data;

  @override
  Widget build(BuildContext context) {
    final isMessage = data.calloutSubtitle == null;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF117F6B),
          child: Icon(
            isMessage ? Icons.person_outline : Icons.check,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.calloutTitle!,
                style: const TextStyle(
                  color: Color(0xFF081820),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (data.calloutSubtitle case final subtitle?)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF52646D),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC1CED4),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF8197A1)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: authSurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: authBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: authBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: authAccent, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.7),
          foregroundColor: const Color(0xFF071820),
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class AuthHelpFooter extends StatelessWidget {
  const AuthHelpFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24, bottom: 18),
      child: Text.rich(
        TextSpan(
          text: 'Precisa de ajuda? ',
          style: TextStyle(color: authMuted, fontSize: 11),
          children: [
            TextSpan(
              text: 'Fale com seu assessor',
              style: TextStyle(
                color: authAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AuthSlideData {
  const _AuthSlideData({
    required this.photoDescription,
    required this.title,
    required this.highlightedTitle,
    required this.subtitle,
    required this.icon,
    this.calloutTitle,
    this.calloutSubtitle,
  });

  final String photoDescription;
  final String title;
  final String highlightedTitle;
  final String subtitle;
  final IconData icon;
  final String? calloutTitle;
  final String? calloutSubtitle;
}

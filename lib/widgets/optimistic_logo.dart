import 'package:flutter/material.dart';

class OptimisticLogo extends StatelessWidget {
  const OptimisticLogo({super.key, this.width = 260});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/optimistic_browser_8k.png',
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => const Icon(
        Icons.public_rounded,
        size: 64,
      ),
    );
  }
}

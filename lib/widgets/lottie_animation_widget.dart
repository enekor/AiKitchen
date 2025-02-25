import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieAnimationWidget extends StatelessWidget {

  const LottieAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.network(
        'https://lottie.host/f463c51a-904f-41ba-a024-d8d4010c3578/E5J7aashlb.json',// Ajusta el modo de ajuste
        width: 250,
        height: 250,
      ),
    );
  }
} 
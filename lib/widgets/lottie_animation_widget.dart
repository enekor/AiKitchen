import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum LottieAnimationType { loading, notfound }

class LottieAnimationWidget extends StatelessWidget {
  const LottieAnimationWidget({
    super.key,
    this.type = LottieAnimationType.loading,
  });
  final LottieAnimationType type;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.network(
        switch (type) {
          LottieAnimationType.loading =>
            'https://lottie.host/f463c51a-904f-41ba-a024-d8d4010c3578/E5J7aashlb.json',
          LottieAnimationType.notfound =>
            'https://lottie.host/f470d155-5981-4643-8eef-e7de4aa64a18/ytkxdRJlcH.json',
        }, // Ajusta el modo de ajuste
        width: 250,
        height: 250,
      ),
    );
  }
}

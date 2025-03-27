import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:sgsits_gym/mainHome.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splashIconSize: 280,
      duration: 2800,
      splash: Column(
        children: [
          Center(
            child: LottieBuilder.asset("assets/splash_screen.json"),
          )
        ],
      ),
      nextScreen: Mainhome(),
      backgroundColor: Colors.blue[100]!,
    );
  }
}

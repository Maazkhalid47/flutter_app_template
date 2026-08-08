import 'package:flutter/material.dart';
import 'package:momflex/constant/app_color/app_colors.dart';

class CounterButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CounterButton({
    super.key, required
    this.text, required
    this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 30,
        height: 30,
        child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.background,
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
        ),
    );
  }
}
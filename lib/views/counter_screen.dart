import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constant/app_color/app_colors.dart';
import '../provider/counter_provider.dart';
import '../widgets/components/counter_button.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CounterProvider>();

    return Scaffold(
      backgroundColor:  AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Counter App'),
      ),
      body: Center(
        child: Container(
          width: 340,
          height: 260,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Counter Value",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CounterButton(
                      text: "-",
                      onPressed: provider.decrement,
                    ),
                    Text(
                      provider.counter.toString(),
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CounterButton(
                      text: "+",
                      onPressed: provider.increment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: provider.reset,
        tooltip: 'Reset',
        child: const Icon(Icons.rotate_left, color: Colors.black,),
      ),
    );
  }
}
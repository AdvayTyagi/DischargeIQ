import 'package:flutter/material.dart';ww
import 'package:go_router/go_router.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              const Icon(
                Icons.health_and_safety,
                size: 76,
              ),

              const SizedBox(height: 24),

              Text(
                'DischargeIQ',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Understand your discharge instructions with confidence.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    context.go('/scan');
                  },
                  child: const Text('Continue'),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Your information stays private.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
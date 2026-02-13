import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  final String? routeName;

  const NotFoundScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "404",
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Page Not Found",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                routeName ?? "",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/splash',
                        (route) => false,
                  );
                },
                child: const Text("Go To Home"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
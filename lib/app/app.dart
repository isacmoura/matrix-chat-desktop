import 'package:flutter/material.dart';

class MatrixDesktopApp extends StatelessWidget {
  const MatrixDesktopApp({
    required this.bridgeStatus,
    super.key,
  });

  final String bridgeStatus;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Matrix Desktop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Matrix Desktop',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(bridgeStatus),
            ],
          ),
        ),
      ),
    );
  }
}

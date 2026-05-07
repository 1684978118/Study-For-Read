import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/reader'),
          child: const Text('Open Reader'),
        ),
      ),
    );
  }
}

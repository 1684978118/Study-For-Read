import 'package:flutter/material.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: Text('Reader')),
      ),
    );
  }
}

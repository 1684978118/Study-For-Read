import 'package:flutter/material.dart';

class ReadingTextView extends StatelessWidget {
  const ReadingTextView({
    super.key,
    required this.text,
    required this.fontSize,
  });

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 56),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.72,
          letterSpacing: 0,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

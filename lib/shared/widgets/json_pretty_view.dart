import 'dart:convert';

import 'package:flutter/material.dart';

class JsonPrettyView extends StatelessWidget {
  const JsonPrettyView({
    super.key,
    required this.value,
  });

  final Object? value;

  @override
  Widget build(BuildContext context) {
    final content = const JsonEncoder.withIndent('  ').convert(value);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: SelectableText(content),
    );
  }
}

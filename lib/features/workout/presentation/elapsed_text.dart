import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';

/// «идёт 32:10» — сколько прошло с [since], обновляется раз в секунду.
class ElapsedText extends StatefulWidget {
  const ElapsedText({super.key, required this.since, this.suffix = ''});

  final DateTime since;
  final String suffix;

  @override
  State<ElapsedText> createState() => _ElapsedTextState();
}

class _ElapsedTextState extends State<ElapsedText> {
  late final Timer _timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = clock.now().difference(widget.since);
    final theme = Theme.of(context);
    return Text(
      'идёт ${formatDuration(elapsed.isNegative ? Duration.zero : elapsed)}${widget.suffix}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontFeatures: tabularFigures,
      ),
    );
  }
}

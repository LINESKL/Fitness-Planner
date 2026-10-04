import 'package:flutter/widgets.dart';

/// Ограничивает ширину контента на планшетах и в альбомной ориентации.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.width = 720});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: child,
    ),
  );
}

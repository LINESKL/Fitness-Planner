import 'package:flutter/material.dart';

import '../../../core/widgets/message_view.dart';

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context) => const MessageView(
    icon: Icons.view_list_outlined,
    text: 'Здесь будет ваш сплит',
  );
}

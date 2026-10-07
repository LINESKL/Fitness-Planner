import 'package:flutter/material.dart';

class TemplateEditorScreen extends StatelessWidget {
  const TemplateEditorScreen({super.key, required this.templateId});

  final String templateId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(templateId == 'new' ? 'Новый день' : 'День')),
  );
}

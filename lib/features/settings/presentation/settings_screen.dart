import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show WatchContext;

import '../../../core/format.dart';
import '../../../core/widgets/max_width.dart';
import '../../auth/presentation/auth_providers.dart';
import 'settings_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = context.watch<SettingsModel>();
    final title = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Тема', style: title),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              // Без галочки подписи помещаются в одну строку на узких экранах.
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Системная'),
                ),
                ButtonSegment(value: ThemeMode.light, label: Text('Светлая')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.single),
            ),
            const SizedBox(height: 24),
            Text('Отдых между подходами', style: title),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final seconds in SettingsModel.restOptions)
                  ChoiceChip(
                    label: Text(
                      seconds == 0
                          ? 'Выкл'
                          : formatDuration(Duration(seconds: seconds)),
                    ),
                    selected: settings.restSeconds == seconds,
                    onSelected: (_) => settings.setRestSeconds(seconds),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: ref.read(authProvider.notifier).signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}

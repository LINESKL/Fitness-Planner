import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' show WatchContext;

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../program/presentation/program_providers.dart';
import '../../progress/presentation/progress_screen.dart' show formatKg;
import '../../settings/presentation/settings_model.dart';
import '../../workout/data/demo_data.dart';
import '../../workout/domain/body.dart';
import '../../workout/domain/progress_rules.dart';
import '../../workout/domain/stats.dart';
import '../../workout/domain/workout.dart';
import '../../workout/presentation/workout_providers.dart';

/// Вкладка «Профиль»: аккаунт, общая статистика, вес тела и настройки.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _loadDemo(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Загрузить пример?'),
        content: const Text(
          'Добавятся программа из трёх дней и месяц тренировок. '
          'Ваши данные останутся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Загрузить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await loadDemo(
      ref.read(workoutRepositoryProvider),
      ref.read(programRepositoryProvider),
      ref.read(bodyRepositoryProvider),
      DateTime.now(),
    );
    ref
      ..invalidate(workoutsProvider)
      ..invalidate(templatesProvider)
      ..invalidate(programProvider)
      ..invalidate(bodyEntriesProvider);
    messenger.showSnackBar(const SnackBar(content: Text('Пример загружен')));
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'Данные останутся в облаке и будут удалены с этого телефона',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(signOutAndWipeProvider)();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = context.watch<SettingsModel>();
    final title = Theme.of(context).textTheme.titleMedium;
    final workouts = ref.watch(workoutsProvider).value ?? const <Workout>[];
    final body = ref.watch(bodyEntriesProvider).value ?? const <BodyEntry>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AccountCard(
          auth: ref.watch(authProvider),
          onSignOut: () => _signOut(context, ref),
          onSignIn: ref.read(authProvider.notifier).signOut,
        ),
        const SizedBox(height: 24),
        Text('Статистика', style: title),
        const SizedBox(height: 8),
        _StatsSection(workouts: workouts),
        const SizedBox(height: 24),
        Text('Тело', style: title),
        const SizedBox(height: 8),
        _BodyCard(entries: body),
        const SizedBox(height: 24),
        Text('Настройки', style: title),
        const SizedBox(height: 16),
        Text('Тема', style: title),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          // Без галочки подписи помещаются в одну строку на узких экранах.
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Системная')),
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
        const SizedBox(height: 24),
        Text('Данные', style: title),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _loadDemo(context, ref),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Загрузить пример'),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.auth,
    required this.onSignOut,
    required this.onSignIn,
  });

  final AuthState auth;
  final VoidCallback onSignOut;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final email = auth is SignedIn ? (auth as SignedIn).email : null;
    final signedIn = auth is SignedIn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: signedIn && email != null && email.isNotEmpty
                      ? Text(email[0].toUpperCase())
                      : Icon(signedIn ? Icons.person : Icons.person_outline),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        signedIn ? (email ?? 'Аккаунт') : 'Гость',
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        signedIn
                            ? 'Синхронизация с облаком'
                            : 'Данные только на этом телефоне',
                        style: muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            signedIn
                ? OutlinedButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                  )
                : FilledButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Войти в аккаунт'),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.workouts});

  /// От старых к новым.
  final List<Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final volume = workouts.fold(0.0, (sum, w) => sum + w.volume);
    final time = workouts.fold(Duration.zero, (sum, w) => sum + w.duration);
    final tiles = [
      ('тренировок', '${workouts.length}'),
      ('тоннаж', formatTonnage(volume)),
      ('часов в зале', '${time.inHours}'),
      ('лучшая серия, нед.', '${bestWeekStreak(workouts)}'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var row = 0; row < tiles.length; row += 2)
          Row(
            children: [
              for (final (label, value) in tiles.skip(row).take(2))
                Expanded(
                  child: Card(
                    key: ValueKey('stat-$label'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                          Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        Text(
          workouts.isEmpty
              ? 'Первая тренировка — впереди'
              : 'Тренируетесь с ${formatLongDate(workouts.first.startedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({required this.entries});

  /// От старых к новым.
  final List<BodyEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final latest = entries.lastOrNull;
    final monthAgo = latest?.date.subtract(const Duration(days: 30));
    final base = monthAgo == null
        ? null
        : entries.where((e) => !e.date.isAfter(monthAgo)).lastOrNull;
    final photo = entries.where((e) => e.photoPath != null).lastOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (latest == null)
                    Text('Записывайте вес раз в неделю', style: muted)
                  else ...[
                    Text(
                      '${formatKg(latest.weightKg)} кг',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                    if (base != null)
                      Text(
                        '${latest.weightKg < base.weightKg ? '−' : '+'}'
                        '${formatKg((latest.weightKg - base.weightKg).abs())} кг за месяц',
                        style: muted,
                      ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.pushNamed('bodyEntryNew'),
                    icon: const Icon(Icons.add),
                    label: const Text('Замер'),
                  ),
                ],
              ),
            ),
            if (photo != null) ...[
              const SizedBox(width: 16),
              ClipRRect(
                key: const ValueKey('profile-photo'),
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(photo.photoPath!),
                  width: 72,
                  height: 72,
                  cacheWidth: 216,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined, size: 72),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

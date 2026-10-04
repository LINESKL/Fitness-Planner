import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/widgets/max_width.dart';

/// Оболочка с вкладками: нижняя панель на телефоне, боковая — на широком экране.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (icon: Icons.home_outlined, selected: Icons.home, label: 'Главная'),
    (icon: Icons.history, selected: Icons.history, label: 'История'),
    (
      icon: Icons.fitness_center,
      selected: Icons.fitness_center,
      label: 'Упражнения',
    ),
  ];

  /// С этой ширины (планшет, альбомная ориентация) — боковая панель.
  static const wideBreakpoint = 600.0;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[shell.currentIndex].label),
        actions: [
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final tab in _tabs)
                      NavigationRailDestination(
                        icon: Icon(tab.icon),
                        selectedIcon: Icon(tab.selected),
                        label: Text(tab.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: MaxWidth(child: shell)),
              ],
            )
          : shell,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _select,
              destinations: [
                for (final tab in _tabs)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selected),
                    label: tab.label,
                  ),
              ],
            ),
    );
  }
}

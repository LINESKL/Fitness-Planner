import 'package:fitness_planner/features/settings/presentation/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SettingsModel> model([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return SettingsModel(await SharedPreferences.getInstance());
  }

  test('по умолчанию — тёмная тема и отдых 90 с', () async {
    final settings = await model();

    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.restSeconds, 90);
  });

  test('тема сохраняется и читается после перезапуска', () async {
    final settings = await model();
    var notified = 0;
    settings.addListener(() => notified++);

    await settings.setThemeMode(ThemeMode.light);

    final restarted = SettingsModel(await SharedPreferences.getInstance());
    expect(restarted.themeMode, ThemeMode.light);
    expect(notified, 1);
  });

  test('время отдыха сохраняется', () async {
    final settings = await model();

    await settings.setRestSeconds(0);

    expect(SettingsModel(await SharedPreferences.getInstance()).restSeconds, 0);
  });

  test('мусор в настройках — значения по умолчанию', () async {
    final settings = await model({'theme_mode': 'neon'});

    expect(settings.themeMode, ThemeMode.dark);
  });
}

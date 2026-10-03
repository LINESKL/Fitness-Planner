import 'package:flutter/material.dart';

const _seed = Colors.deepOrange;

final lightTheme = ThemeData(colorSchemeSeed: _seed);
final darkTheme = ThemeData(
  colorSchemeSeed: _seed,
  brightness: Brightness.dark,
);

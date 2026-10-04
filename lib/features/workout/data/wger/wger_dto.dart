import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/exercise.dart';

part 'wger_dto.freezed.dart';
part 'wger_dto.g.dart';

/// Ответ `GET /api/v2/exerciseinfo/` — только нужные поля.
@freezed
abstract class WgerExerciseDto with _$WgerExerciseDto {
  const factory WgerExerciseDto({
    required int id,
    required WgerCategoryDto category,
    @Default([]) List<WgerTranslationDto> translations,
    @Default([]) List<WgerImageDto> images,
  }) = _WgerExerciseDto;

  factory WgerExerciseDto.fromJson(Map<String, dynamic> json) =>
      _$WgerExerciseDtoFromJson(json);
}

@freezed
abstract class WgerCategoryDto with _$WgerCategoryDto {
  const factory WgerCategoryDto({required String name}) = _WgerCategoryDto;

  factory WgerCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$WgerCategoryDtoFromJson(json);
}

@freezed
abstract class WgerTranslationDto with _$WgerTranslationDto {
  const factory WgerTranslationDto({
    required int language,
    required String name,
  }) = _WgerTranslationDto;

  factory WgerTranslationDto.fromJson(Map<String, dynamic> json) =>
      _$WgerTranslationDtoFromJson(json);
}

@freezed
abstract class WgerImageDto with _$WgerImageDto {
  const factory WgerImageDto({
    required String image,
    @JsonKey(name: 'is_main') @Default(false) bool isMain,
  }) = _WgerImageDto;

  factory WgerImageDto.fromJson(Map<String, dynamic> json) =>
      _$WgerImageDtoFromJson(json);
}

const _russian = 5;
const _english = 2;

const _categories = {
  'Abs': 'Пресс',
  'Arms': 'Руки',
  'Back': 'Спина',
  'Calves': 'Икры',
  'Cardio': 'Кардио',
  'Chest': 'Грудь',
  'Legs': 'Ноги',
  'Shoulders': 'Плечи',
};

extension WgerExerciseMapper on WgerExerciseDto {
  /// null — если нет ни русского, ни английского названия.
  Exercise? toExercise() {
    String? nameIn(int language) => translations
        .where((t) => t.language == language && t.name.trim().isNotEmpty)
        .firstOrNull
        ?.name
        .trim();

    final name = nameIn(_russian) ?? nameIn(_english);
    if (name == null) return null;

    return Exercise(
      id: 'wger-$id',
      name: name,
      muscleGroup: _categories[category.name] ?? category.name,
      imageUrl:
          (images.where((i) => i.isMain).firstOrNull ?? images.firstOrNull)
              ?.image,
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wger_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WgerExerciseDto _$WgerExerciseDtoFromJson(
  Map<String, dynamic> json,
) => _WgerExerciseDto(
  id: (json['id'] as num).toInt(),
  category: WgerCategoryDto.fromJson(json['category'] as Map<String, dynamic>),
  translations:
      (json['translations'] as List<dynamic>?)
          ?.map((e) => WgerTranslationDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => WgerImageDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$WgerExerciseDtoToJson(_WgerExerciseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'translations': instance.translations,
      'images': instance.images,
    };

_WgerCategoryDto _$WgerCategoryDtoFromJson(Map<String, dynamic> json) =>
    _WgerCategoryDto(name: json['name'] as String);

Map<String, dynamic> _$WgerCategoryDtoToJson(_WgerCategoryDto instance) =>
    <String, dynamic>{'name': instance.name};

_WgerTranslationDto _$WgerTranslationDtoFromJson(Map<String, dynamic> json) =>
    _WgerTranslationDto(
      language: (json['language'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$WgerTranslationDtoToJson(_WgerTranslationDto instance) =>
    <String, dynamic>{'language': instance.language, 'name': instance.name};

_WgerImageDto _$WgerImageDtoFromJson(Map<String, dynamic> json) =>
    _WgerImageDto(
      image: json['image'] as String,
      isMain: json['is_main'] as bool? ?? false,
    );

Map<String, dynamic> _$WgerImageDtoToJson(_WgerImageDto instance) =>
    <String, dynamic>{'image': instance.image, 'is_main': instance.isMain};

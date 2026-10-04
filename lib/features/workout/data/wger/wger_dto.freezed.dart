// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wger_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WgerExerciseDto {

 int get id; WgerCategoryDto get category; List<WgerTranslationDto> get translations; List<WgerImageDto> get images;
/// Create a copy of WgerExerciseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WgerExerciseDtoCopyWith<WgerExerciseDto> get copyWith => _$WgerExerciseDtoCopyWithImpl<WgerExerciseDto>(this as WgerExerciseDto, _$identity);

  /// Serializes this WgerExerciseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WgerExerciseDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WgerExerciseDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.category, _this.category) || other.category == _this.category)&&const DeepCollectionEquality().equals(other.translations, _this.translations)&&const DeepCollectionEquality().equals(other.images, _this.images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WgerExerciseDto;
  return Object.hash(runtimeType,_this.id,_this.category,const DeepCollectionEquality().hash(_this.translations),const DeepCollectionEquality().hash(_this.images));
}

@override
String toString() {
  final _this = this as WgerExerciseDto;
  return 'WgerExerciseDto(id: ${_this.id}, category: ${_this.category}, translations: ${_this.translations}, images: ${_this.images})';
}


}

/// @nodoc
abstract mixin class $WgerExerciseDtoCopyWith<$Res>  {
  factory $WgerExerciseDtoCopyWith(WgerExerciseDto value, $Res Function(WgerExerciseDto) _then) = _$WgerExerciseDtoCopyWithImpl;
@useResult
$Res call({
 int id, WgerCategoryDto category, List<WgerTranslationDto> translations, List<WgerImageDto> images
});


$WgerCategoryDtoCopyWith<$Res> get category;

}
/// @nodoc
class _$WgerExerciseDtoCopyWithImpl<$Res>
    implements $WgerExerciseDtoCopyWith<$Res> {
  _$WgerExerciseDtoCopyWithImpl(this._self, this._then);

  final WgerExerciseDto _self;
  final $Res Function(WgerExerciseDto) _then;

/// Create a copy of WgerExerciseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? translations = null,Object? images = null,}) {
  return _then(WgerExerciseDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WgerCategoryDto,translations: null == translations ? _self.translations : translations // ignore: cast_nullable_to_non_nullable
as List<WgerTranslationDto>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<WgerImageDto>,
  ));
}
/// Create a copy of WgerExerciseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WgerCategoryDtoCopyWith<$Res> get category {
  
  return $WgerCategoryDtoCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [WgerExerciseDto].
extension WgerExerciseDtoPatterns on WgerExerciseDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WgerExerciseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WgerExerciseDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WgerExerciseDto value)  $default,){
final _that = this;
switch (_that) {
case _WgerExerciseDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WgerExerciseDto value)?  $default,){
final _that = this;
switch (_that) {
case _WgerExerciseDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  WgerCategoryDto category,  List<WgerTranslationDto> translations,  List<WgerImageDto> images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WgerExerciseDto() when $default != null:
return $default(_that.id,_that.category,_that.translations,_that.images);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  WgerCategoryDto category,  List<WgerTranslationDto> translations,  List<WgerImageDto> images)  $default,) {final _that = this;
switch (_that) {
case _WgerExerciseDto():
return $default(_that.id,_that.category,_that.translations,_that.images);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  WgerCategoryDto category,  List<WgerTranslationDto> translations,  List<WgerImageDto> images)?  $default,) {final _that = this;
switch (_that) {
case _WgerExerciseDto() when $default != null:
return $default(_that.id,_that.category,_that.translations,_that.images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WgerExerciseDto implements WgerExerciseDto {
  const _WgerExerciseDto({required this.id, required this.category,  List<WgerTranslationDto> translations = const [],  List<WgerImageDto> images = const []}): _translations = translations,_images = images;
  factory _WgerExerciseDto.fromJson(Map<String, dynamic> json) => _$WgerExerciseDtoFromJson(json);

@override final  int id;
@override final  WgerCategoryDto category;
 final  List<WgerTranslationDto> _translations;
@override@JsonKey() List<WgerTranslationDto> get translations {
  if (_translations is EqualUnmodifiableListView) return _translations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_translations);
}

 final  List<WgerImageDto> _images;
@override@JsonKey() List<WgerImageDto> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}


/// Create a copy of WgerExerciseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WgerExerciseDtoCopyWith<_WgerExerciseDto> get copyWith => __$WgerExerciseDtoCopyWithImpl<_WgerExerciseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WgerExerciseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WgerExerciseDto&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.translations, _translations)&&const DeepCollectionEquality().equals(other.images, _images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,category,const DeepCollectionEquality().hash(_translations),const DeepCollectionEquality().hash(_images));
}

@override
String toString() {
    return 'WgerExerciseDto(id: $id, category: $category, translations: $translations, images: $images)';
}


}

/// @nodoc
abstract mixin class _$WgerExerciseDtoCopyWith<$Res> implements $WgerExerciseDtoCopyWith<$Res> {
  factory _$WgerExerciseDtoCopyWith(_WgerExerciseDto value, $Res Function(_WgerExerciseDto) _then) = __$WgerExerciseDtoCopyWithImpl;
@override @useResult
$Res call({
 int id, WgerCategoryDto category, List<WgerTranslationDto> translations, List<WgerImageDto> images
});


@override $WgerCategoryDtoCopyWith<$Res> get category;

}
/// @nodoc
class __$WgerExerciseDtoCopyWithImpl<$Res>
    implements _$WgerExerciseDtoCopyWith<$Res> {
  __$WgerExerciseDtoCopyWithImpl(this._self, this._then);

  final _WgerExerciseDto _self;
  final $Res Function(_WgerExerciseDto) _then;

/// Create a copy of WgerExerciseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? translations = null,Object? images = null,}) {
  return _then(_WgerExerciseDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as WgerCategoryDto,translations: null == translations ? _self._translations : translations // ignore: cast_nullable_to_non_nullable
as List<WgerTranslationDto>,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<WgerImageDto>,
  ));
}

/// Create a copy of WgerExerciseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WgerCategoryDtoCopyWith<$Res> get category {
  
  return $WgerCategoryDtoCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// @nodoc
mixin _$WgerCategoryDto {

 String get name;
/// Create a copy of WgerCategoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WgerCategoryDtoCopyWith<WgerCategoryDto> get copyWith => _$WgerCategoryDtoCopyWithImpl<WgerCategoryDto>(this as WgerCategoryDto, _$identity);

  /// Serializes this WgerCategoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WgerCategoryDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WgerCategoryDto&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WgerCategoryDto;
  return Object.hash(runtimeType,_this.name);
}

@override
String toString() {
  final _this = this as WgerCategoryDto;
  return 'WgerCategoryDto(name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $WgerCategoryDtoCopyWith<$Res>  {
  factory $WgerCategoryDtoCopyWith(WgerCategoryDto value, $Res Function(WgerCategoryDto) _then) = _$WgerCategoryDtoCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$WgerCategoryDtoCopyWithImpl<$Res>
    implements $WgerCategoryDtoCopyWith<$Res> {
  _$WgerCategoryDtoCopyWithImpl(this._self, this._then);

  final WgerCategoryDto _self;
  final $Res Function(WgerCategoryDto) _then;

/// Create a copy of WgerCategoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,}) {
  return _then(WgerCategoryDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WgerCategoryDto].
extension WgerCategoryDtoPatterns on WgerCategoryDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WgerCategoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WgerCategoryDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WgerCategoryDto value)  $default,){
final _that = this;
switch (_that) {
case _WgerCategoryDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WgerCategoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _WgerCategoryDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WgerCategoryDto() when $default != null:
return $default(_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name)  $default,) {final _that = this;
switch (_that) {
case _WgerCategoryDto():
return $default(_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name)?  $default,) {final _that = this;
switch (_that) {
case _WgerCategoryDto() when $default != null:
return $default(_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WgerCategoryDto implements WgerCategoryDto {
  const _WgerCategoryDto({required this.name});
  factory _WgerCategoryDto.fromJson(Map<String, dynamic> json) => _$WgerCategoryDtoFromJson(json);

@override final  String name;

/// Create a copy of WgerCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WgerCategoryDtoCopyWith<_WgerCategoryDto> get copyWith => __$WgerCategoryDtoCopyWithImpl<_WgerCategoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WgerCategoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WgerCategoryDto&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name);
}

@override
String toString() {
    return 'WgerCategoryDto(name: $name)';
}


}

/// @nodoc
abstract mixin class _$WgerCategoryDtoCopyWith<$Res> implements $WgerCategoryDtoCopyWith<$Res> {
  factory _$WgerCategoryDtoCopyWith(_WgerCategoryDto value, $Res Function(_WgerCategoryDto) _then) = __$WgerCategoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String name
});




}
/// @nodoc
class __$WgerCategoryDtoCopyWithImpl<$Res>
    implements _$WgerCategoryDtoCopyWith<$Res> {
  __$WgerCategoryDtoCopyWithImpl(this._self, this._then);

  final _WgerCategoryDto _self;
  final $Res Function(_WgerCategoryDto) _then;

/// Create a copy of WgerCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_WgerCategoryDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WgerTranslationDto {

 int get language; String get name;
/// Create a copy of WgerTranslationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WgerTranslationDtoCopyWith<WgerTranslationDto> get copyWith => _$WgerTranslationDtoCopyWithImpl<WgerTranslationDto>(this as WgerTranslationDto, _$identity);

  /// Serializes this WgerTranslationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WgerTranslationDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WgerTranslationDto&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WgerTranslationDto;
  return Object.hash(runtimeType,_this.language,_this.name);
}

@override
String toString() {
  final _this = this as WgerTranslationDto;
  return 'WgerTranslationDto(language: ${_this.language}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $WgerTranslationDtoCopyWith<$Res>  {
  factory $WgerTranslationDtoCopyWith(WgerTranslationDto value, $Res Function(WgerTranslationDto) _then) = _$WgerTranslationDtoCopyWithImpl;
@useResult
$Res call({
 int language, String name
});




}
/// @nodoc
class _$WgerTranslationDtoCopyWithImpl<$Res>
    implements $WgerTranslationDtoCopyWith<$Res> {
  _$WgerTranslationDtoCopyWithImpl(this._self, this._then);

  final WgerTranslationDto _self;
  final $Res Function(WgerTranslationDto) _then;

/// Create a copy of WgerTranslationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? name = null,}) {
  return _then(WgerTranslationDto(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WgerTranslationDto].
extension WgerTranslationDtoPatterns on WgerTranslationDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WgerTranslationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WgerTranslationDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WgerTranslationDto value)  $default,){
final _that = this;
switch (_that) {
case _WgerTranslationDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WgerTranslationDto value)?  $default,){
final _that = this;
switch (_that) {
case _WgerTranslationDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int language,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WgerTranslationDto() when $default != null:
return $default(_that.language,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int language,  String name)  $default,) {final _that = this;
switch (_that) {
case _WgerTranslationDto():
return $default(_that.language,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int language,  String name)?  $default,) {final _that = this;
switch (_that) {
case _WgerTranslationDto() when $default != null:
return $default(_that.language,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WgerTranslationDto implements WgerTranslationDto {
  const _WgerTranslationDto({required this.language, required this.name});
  factory _WgerTranslationDto.fromJson(Map<String, dynamic> json) => _$WgerTranslationDtoFromJson(json);

@override final  int language;
@override final  String name;

/// Create a copy of WgerTranslationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WgerTranslationDtoCopyWith<_WgerTranslationDto> get copyWith => __$WgerTranslationDtoCopyWithImpl<_WgerTranslationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WgerTranslationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WgerTranslationDto&&(identical(other.language, language) || other.language == language)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,language,name);
}

@override
String toString() {
    return 'WgerTranslationDto(language: $language, name: $name)';
}


}

/// @nodoc
abstract mixin class _$WgerTranslationDtoCopyWith<$Res> implements $WgerTranslationDtoCopyWith<$Res> {
  factory _$WgerTranslationDtoCopyWith(_WgerTranslationDto value, $Res Function(_WgerTranslationDto) _then) = __$WgerTranslationDtoCopyWithImpl;
@override @useResult
$Res call({
 int language, String name
});




}
/// @nodoc
class __$WgerTranslationDtoCopyWithImpl<$Res>
    implements _$WgerTranslationDtoCopyWith<$Res> {
  __$WgerTranslationDtoCopyWithImpl(this._self, this._then);

  final _WgerTranslationDto _self;
  final $Res Function(_WgerTranslationDto) _then;

/// Create a copy of WgerTranslationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? name = null,}) {
  return _then(_WgerTranslationDto(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WgerImageDto {

 String get image;@JsonKey(name: 'is_main') bool get isMain;
/// Create a copy of WgerImageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WgerImageDtoCopyWith<WgerImageDto> get copyWith => _$WgerImageDtoCopyWithImpl<WgerImageDto>(this as WgerImageDto, _$identity);

  /// Serializes this WgerImageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WgerImageDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WgerImageDto&&(identical(other.image, _this.image) || other.image == _this.image)&&(identical(other.isMain, _this.isMain) || other.isMain == _this.isMain));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WgerImageDto;
  return Object.hash(runtimeType,_this.image,_this.isMain);
}

@override
String toString() {
  final _this = this as WgerImageDto;
  return 'WgerImageDto(image: ${_this.image}, isMain: ${_this.isMain})';
}


}

/// @nodoc
abstract mixin class $WgerImageDtoCopyWith<$Res>  {
  factory $WgerImageDtoCopyWith(WgerImageDto value, $Res Function(WgerImageDto) _then) = _$WgerImageDtoCopyWithImpl;
@useResult
$Res call({
 String image,@JsonKey(name: 'is_main') bool isMain
});




}
/// @nodoc
class _$WgerImageDtoCopyWithImpl<$Res>
    implements $WgerImageDtoCopyWith<$Res> {
  _$WgerImageDtoCopyWithImpl(this._self, this._then);

  final WgerImageDto _self;
  final $Res Function(WgerImageDto) _then;

/// Create a copy of WgerImageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? image = null,Object? isMain = null,}) {
  return _then(WgerImageDto(
image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,isMain: null == isMain ? _self.isMain : isMain // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WgerImageDto].
extension WgerImageDtoPatterns on WgerImageDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WgerImageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WgerImageDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WgerImageDto value)  $default,){
final _that = this;
switch (_that) {
case _WgerImageDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WgerImageDto value)?  $default,){
final _that = this;
switch (_that) {
case _WgerImageDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String image, @JsonKey(name: 'is_main')  bool isMain)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WgerImageDto() when $default != null:
return $default(_that.image,_that.isMain);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String image, @JsonKey(name: 'is_main')  bool isMain)  $default,) {final _that = this;
switch (_that) {
case _WgerImageDto():
return $default(_that.image,_that.isMain);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String image, @JsonKey(name: 'is_main')  bool isMain)?  $default,) {final _that = this;
switch (_that) {
case _WgerImageDto() when $default != null:
return $default(_that.image,_that.isMain);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WgerImageDto implements WgerImageDto {
  const _WgerImageDto({required this.image, @JsonKey(name: 'is_main') this.isMain = false});
  factory _WgerImageDto.fromJson(Map<String, dynamic> json) => _$WgerImageDtoFromJson(json);

@override final  String image;
@override@JsonKey(name: 'is_main') final  bool isMain;

/// Create a copy of WgerImageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WgerImageDtoCopyWith<_WgerImageDto> get copyWith => __$WgerImageDtoCopyWithImpl<_WgerImageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WgerImageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WgerImageDto&&(identical(other.image, image) || other.image == image)&&(identical(other.isMain, isMain) || other.isMain == isMain));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,image,isMain);
}

@override
String toString() {
    return 'WgerImageDto(image: $image, isMain: $isMain)';
}


}

/// @nodoc
abstract mixin class _$WgerImageDtoCopyWith<$Res> implements $WgerImageDtoCopyWith<$Res> {
  factory _$WgerImageDtoCopyWith(_WgerImageDto value, $Res Function(_WgerImageDto) _then) = __$WgerImageDtoCopyWithImpl;
@override @useResult
$Res call({
 String image,@JsonKey(name: 'is_main') bool isMain
});




}
/// @nodoc
class __$WgerImageDtoCopyWithImpl<$Res>
    implements _$WgerImageDtoCopyWith<$Res> {
  __$WgerImageDtoCopyWithImpl(this._self, this._then);

  final _WgerImageDto _self;
  final $Res Function(_WgerImageDto) _then;

/// Create a copy of WgerImageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? image = null,Object? isMain = null,}) {
  return _then(_WgerImageDto(
image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,isMain: null == isMain ? _self.isMain : isMain // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String muscleGroup;
  final String? imageUrl;
}

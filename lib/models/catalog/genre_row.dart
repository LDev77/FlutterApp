import 'catalog_story.dart';

class GenreRow {
  final String genreTitle;
  final String subtitle;
  final List<CatalogStory> stories;

  const GenreRow({
    required this.genreTitle,
    required this.subtitle,
    required this.stories,
  });

  factory GenreRow.fromJson(Map<String, dynamic> json) {
    return GenreRow(
      genreTitle: json['genreTitle'] as String,
      subtitle: json['subtitle'] as String,
      stories: (json['stories'] as List)
          .map((storyJson) => CatalogStory.fromJson(storyJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'genreTitle': genreTitle,
      'subtitle': subtitle,
      'stories': stories.map((story) => story.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'GenreRow{genreTitle: $genreTitle, subtitle: $subtitle, storiesCount: ${stories.length}}';
  }
}
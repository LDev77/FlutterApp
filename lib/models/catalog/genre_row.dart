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
          .map((storyJson) {
            // Handle LinkedMap from Hive storage
            if (storyJson is Map<String, dynamic>) {
              return CatalogStory.fromJson(storyJson);
            } else if (storyJson is Map) {
              return CatalogStory.fromJson(Map<String, dynamic>.from(storyJson));
            } else {
              throw Exception('Invalid story data type: ${storyJson.runtimeType}');
            }
          })
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
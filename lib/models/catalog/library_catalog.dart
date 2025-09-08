import 'genre_row.dart';
import 'catalog_story.dart';

class LibraryCatalog {
  final String appTitle;
  final String headerSubtitle;
  final String welcomeMessage;
  final List<GenreRow> genreRows;
  final DateTime lastUpdated;

  const LibraryCatalog({
    required this.appTitle,
    required this.headerSubtitle,
    required this.welcomeMessage,
    required this.genreRows,
    required this.lastUpdated,
  });

  factory LibraryCatalog.fromJson(Map<String, dynamic> json) {
    return LibraryCatalog(
      appTitle: json['appTitle'] as String,
      headerSubtitle: json['headerSubtitle'] as String,
      welcomeMessage: json['welcomeMessage'] as String,
      genreRows: (json['genreRows'] as List)
          .map((rowJson) => GenreRow.fromJson(rowJson as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appTitle': appTitle,
      'headerSubtitle': headerSubtitle,
      'welcomeMessage': welcomeMessage,
      'genreRows': genreRows.map((row) => row.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Get total number of stories across all genres
  int get totalStories {
    return genreRows.fold(0, (sum, row) => sum + row.stories.length);
  }

  /// Find a specific story by ID across all genres
  ({GenreRow? genreRow, CatalogStory? story}) findStoryById(String storyId) {
    for (final genreRow in genreRows) {
      for (final story in genreRow.stories) {
        if (story.storyId == storyId) {
          return (genreRow: genreRow, story: story);
        }
      }
    }
    return (genreRow: null, story: null);
  }

  @override
  String toString() {
    return 'LibraryCatalog{appTitle: $appTitle, genreRowsCount: ${genreRows.length}, totalStories: $totalStories}';
  }
}
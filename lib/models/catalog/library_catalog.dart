import 'genre_row.dart';
import 'catalog_story.dart';
import '../story_metadata.dart';

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
          .map((rowJson) {
            // Handle LinkedMap from Hive storage
            if (rowJson is Map<String, dynamic>) {
              return GenreRow.fromJson(rowJson);
            } else if (rowJson is Map) {
              return GenreRow.fromJson(Map<String, dynamic>.from(rowJson));
            } else {
              throw Exception('Invalid genreRow data type: ${rowJson.runtimeType}');
            }
          })
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

  /// Sort stories within each genre by last played date (most recent first)
  LibraryCatalog sortStoriesByLastPlayed(List<StoryMetadata> allMetadata) {
    // Create a map for quick metadata lookups
    final metadataMap = <String, StoryMetadata>{};
    for (final metadata in allMetadata) {
      metadataMap[metadata.storyId] = metadata;
    }

    // Sort stories within each genre row
    final sortedGenreRows = genreRows.map((genreRow) {
      final sortedStories = List<CatalogStory>.from(genreRow.stories);
      
      sortedStories.sort((a, b) {
        final aMetadata = metadataMap[a.storyId];
        final bMetadata = metadataMap[b.storyId];
        
        // Stories with lastPlayedAt come first, sorted by most recent
        if (aMetadata?.lastPlayedAt != null && bMetadata?.lastPlayedAt != null) {
          return bMetadata!.lastPlayedAt!.compareTo(aMetadata!.lastPlayedAt!);
        }
        
        // Played stories come before unplayed
        if (aMetadata?.lastPlayedAt != null && bMetadata?.lastPlayedAt == null) {
          return -1;
        }
        if (aMetadata?.lastPlayedAt == null && bMetadata?.lastPlayedAt != null) {
          return 1;
        }
        
        // Both unplayed - maintain original order
        return 0;
      });

      return GenreRow(
        genreTitle: genreRow.genreTitle,
        subtitle: genreRow.subtitle,
        stories: sortedStories,
      );
    }).toList();

    return LibraryCatalog(
      appTitle: appTitle,
      headerSubtitle: headerSubtitle,
      welcomeMessage: welcomeMessage,
      genreRows: sortedGenreRows,
      lastUpdated: lastUpdated,
    );
  }

  @override
  String toString() {
    return 'LibraryCatalog{appTitle: $appTitle, genreRowsCount: ${genreRows.length}, totalStories: $totalStories}';
  }
}
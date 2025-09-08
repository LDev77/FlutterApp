class CatalogStory {
  final String storyId;
  final String coverImageUri;
  final String title;
  final String subtitle;
  final String marketingCopy;
  final int estimatedTurns;
  final List<String> tags;

  const CatalogStory({
    required this.storyId,
    required this.coverImageUri,
    required this.title,
    required this.subtitle,
    required this.marketingCopy,
    required this.estimatedTurns,
    required this.tags,
  });

  factory CatalogStory.fromJson(Map<String, dynamic> json) {
    return CatalogStory(
      storyId: json['storyId'] as String,
      coverImageUri: json['coverImageUri'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      marketingCopy: json['marketingCopy'] as String,
      estimatedTurns: json['estimatedTurns'] as int,
      tags: List<String>.from(json['tags'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'coverImageUri': coverImageUri,
      'title': title,
      'subtitle': subtitle,
      'marketingCopy': marketingCopy,
      'estimatedTurns': estimatedTurns,
      'tags': tags,
    };
  }

  @override
  String toString() {
    return 'CatalogStory{storyId: $storyId, title: $title, estimatedTurns: $estimatedTurns, tags: $tags}';
  }
}
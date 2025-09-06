// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:infiniteer_app/models/story.dart';

void main() {
  test('Story model creation', () {
    // Test story model functionality
    final story = Story(
      id: 'test',
      title: 'Test Story',
      description: 'Test Description',
      coverUrl: 'https://test.com/image.jpg',
      genre: 'Test',
      introText: 'Test intro',
    );
    
    expect(story.id, equals('test'));
    expect(story.title, equals('Test Story'));
    expect(story.isAdult, equals(false));
    expect(story.estimatedTurns, equals(20));
  });
}

import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// Centralized text styles for story content only
/// These styles scale with user's font size preference
class StoryTextStyles {
  // Get current font scale from ThemeService
  static double get _scale => ThemeService.instance.storyFontScale;

  // Narrative text styles
  static TextStyle get narrative => TextStyle(
    fontSize: 16 * _scale,
    height: 1.5,
    color: null, // Use theme color
  );

  static TextStyle get narrativeEmphasis => TextStyle(
    fontSize: 16 * _scale,
    height: 1.5,
    fontWeight: FontWeight.bold,
    color: null, // Use theme color
  );

  // Choice/option styles
  static TextStyle get choiceOption => TextStyle(
    fontSize: 16 * _scale,
    height: 1.4,
    color: Colors.purple,
    fontWeight: FontWeight.w400,
  );

  // User input styles
  static TextStyle get userInput => TextStyle(
    fontSize: 16 * _scale,
    height: 1.4,
    color: null, // Use theme color
  );

  static TextStyle get inputHint => TextStyle(
    fontSize: 16 * _scale,
    height: 1.4,
    color: Colors.grey,
  );

  // Peek content styles
  static TextStyle get peekContent => TextStyle(
    fontSize: 14 * _scale,
    height: 1.4,
    color: null, // Use theme color
  );

  // Story description on cover
  static TextStyle get storyDescription => TextStyle(
    fontSize: 16 * _scale,
    height: 1.4,
    color: null, // Use theme color
  );

  // Turn number/metadata
  static TextStyle get turnMetadata => TextStyle(
    fontSize: 12 * _scale,
    color: Colors.grey,
    fontWeight: FontWeight.w500,
  );

  // Input suggestions
  static TextStyle get suggestion => TextStyle(
    fontSize: 13 * _scale,
    color: Colors.purple,
    fontWeight: FontWeight.w500,
  );
}
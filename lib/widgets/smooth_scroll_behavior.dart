import 'package:flutter/material.dart';

// Custom scroll behavior for smooth scrolling across platforms
class SilkyScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Remove Android glow effect for consistent look
  }
}

// Horizontal snapping physics for Netflix-style catalog rows
class HorizontalSnapScrollPhysics extends ScrollPhysics {
  final double itemWidth;
  final double screenWidth;

  const HorizontalSnapScrollPhysics({
    required this.itemWidth,
    required this.screenWidth,
    super.parent,
  });

  @override
  HorizontalSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HorizontalSnapScrollPhysics(
      itemWidth: itemWidth,
      screenWidth: screenWidth,
      parent: buildParent(ancestor),
    );
  }

  double _getTargetPixels(ScrollMetrics position, Tolerance tolerance, double velocity) {
    // Calculate the center of the screen
    final double screenCenter = screenWidth / 2;

    // Account for the first side block (bookWidth / 4) when calculating item positions
    final double sideBlockWidth = (itemWidth - 24.0) / 4; // Remove margins, then divide by 4
    final double firstItemCenter = sideBlockWidth + (itemWidth / 2); // First actual item center

    // Calculate current position relative to first item center
    final double relativePosition = position.pixels + screenCenter - firstItemCenter;
    final double currentItem = relativePosition / itemWidth;

    // Determine target item based on velocity and current position
    final double targetItem;
    if (velocity < -tolerance.velocity) {
      // Scrolling left - snap to previous item
      targetItem = currentItem.floor().toDouble();
    } else if (velocity > tolerance.velocity) {
      // Scrolling right - snap to next item
      targetItem = currentItem.ceil().toDouble();
    } else {
      // Low velocity - snap to nearest item
      targetItem = currentItem.round().toDouble();
    }

    // Calculate target pixels to center the item
    final double targetPixels = (targetItem * itemWidth) + firstItemCenter - screenCenter;

    // Clamp to valid scroll range
    return targetPixels.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // Use default behavior if at boundaries or low precision
    final Tolerance tolerance = toleranceFor(position);

    // If we're at the boundaries, use default physics
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double target = _getTargetPixels(position, tolerance, velocity);

    // If target is the same as current position, no need to animate
    if ((target - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    // Create smooth snapping animation
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}

// Vertical snapping physics for genre rows
class VerticalSnapScrollPhysics extends ScrollPhysics {
  final double rowHeight;
  final double appBarHeight;
  final double heroHeight;
  final double screenHeight;

  const VerticalSnapScrollPhysics({
    required this.rowHeight,
    required this.appBarHeight,
    required this.heroHeight,
    required this.screenHeight,
    super.parent,
  });

  @override
  VerticalSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return VerticalSnapScrollPhysics(
      rowHeight: rowHeight,
      appBarHeight: appBarHeight,
      heroHeight: heroHeight,
      screenHeight: screenHeight,
      parent: buildParent(ancestor),
    );
  }

  double _getTargetPixels(ScrollMetrics position, Tolerance tolerance, double velocity) {
    // Account for app bar and hero section in calculations
    final double effectiveRowHeight = rowHeight + 30; // Row height + bottom margin
    final double heroSectionEnd = heroHeight + 32; // Hero height + margins
    final double availableScreenHeight = screenHeight - appBarHeight; // Viewport height excluding app bar

    // Calculate current scroll position
    final double scrollPosition = position.pixels;

    // Special case: if we're in the hero section area, snap to show it fully
    if (scrollPosition < heroSectionEnd) {
      if (velocity < -tolerance.velocity || scrollPosition < heroSectionEnd / 2) {
        return 0.0; // Snap to top to show hero fully
      } else {
        return heroSectionEnd; // Snap to just past hero
      }
    }

    // For rows beyond hero section, center them in the viewport
    final double relativePosition = scrollPosition - heroSectionEnd;
    final double currentRow = relativePosition / effectiveRowHeight;

    // Determine target row based on velocity and current position
    final double targetRow;
    if (velocity < -tolerance.velocity) {
      // Scrolling up - snap to previous row
      targetRow = currentRow.floor().toDouble();
    } else if (velocity > tolerance.velocity) {
      // Scrolling down - snap to next row
      targetRow = currentRow.ceil().toDouble();
    } else {
      // Low velocity - snap to nearest row
      targetRow = currentRow.round().toDouble();
    }

    // Calculate target pixels to CENTER the row in the viewport
    // We want the row to be centered in the available screen space
    final double rowStartPosition = heroSectionEnd + (targetRow * effectiveRowHeight);
    final double centerOffset = (availableScreenHeight - rowHeight) / 2;
    final double targetPixels = rowStartPosition - centerOffset;

    // Clamp to valid scroll range
    return targetPixels.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Tolerance tolerance = toleranceFor(position);

    // If we're at the boundaries, use default physics
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double target = _getTargetPixels(position, tolerance, velocity);

    // If target is the same as current position, no need to animate
    if ((target - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    // Create smooth snapping animation
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
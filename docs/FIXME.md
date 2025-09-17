# FIXME - Code Quality Issues

*Created: 2025-09-17*
*Status: Deferred - More pressing bugs take priority*

## Overview
Flutter analysis found 218 issues that need to be addressed for code quality and maintainability. These are deferred in favor of more critical bugs.

## Analysis Issues Breakdown

### 1. Deprecated API Usage (High Priority)
- **withOpacity() calls**: ~150+ instances need to be replaced with `.withValues(alpha: X)`
  - Affects multiple files across widgets/ and screens/
  - Performance and future compatibility impact

### 2. Performance Optimizations (Medium Priority)
- **const constructors**: ~80+ missing const keywords
- **prefer_final_fields**: Several fields can be made final
- **SizedBox vs Container**: Replace empty Containers with SizedBox for whitespace

### 3. Code Cleanup (Low Priority)
- **Unused imports**: ✅ COMPLETED - Fixed dart:math and theme_service imports
- **Unused elements**: Remove unused methods and fields
- **prefer_const_literals**: Use const for immutable constructor arguments

### 4. Documentation Issues
- **Dangling library doc comments**: Fix format in api_models.dart

## Files Most Affected
- `lib/screens/infiniteerium_purchase_screen.dart`
- `lib/widgets/` (multiple files)
- `lib/screens/story_reader_screen.dart`

## Current Todo List Status
1. ✅ Fix unused imports across the codebase
2. ⏸️ Replace deprecated withOpacity() calls with withValues()
3. ⏸️ Add const constructors where recommended
4. ⏸️ Fix dangling library doc comments
5. ⏸️ Remove unused elements and fields
6. ⏸️ Replace Container with SizedBox for whitespace
7. ⏸️ Make fields final where possible
8. ⏸️ Run final analysis to ensure all issues are resolved

## Commands to Resume Work
```bash
flutter analyze                    # Check current issues
```

## Notes
- All issues are linting/performance related, no functional bugs
- Can be addressed during next maintenance cycle
- Priority should be given to user-facing bugs and critical functionality
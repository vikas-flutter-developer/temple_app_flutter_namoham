import re

# Read the file
with open(r'c:\Users\Vikas\AndroidStudioProjects\temple\lib\features\reels\presentation\screens\video_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Step 1: Add cleanup call in _onPageChanged (after setState, before "Pause previous video")
pattern1 = r'(setState\(\(\) \{\s+_currentIndex = index;\s+\}\);)\s+(// Pause previous video)'
replacement1 = r'\1\n\n    // Cleanup old controllers to prevent memory leaks\n    _cleanupOldControllers(index, reels);\n\n    \2'
content = re.sub(pattern1, replacement1, content)

# Step 2: Add the cleanup method after _onPageChanged method ends (before @override)
cleanup_method = '''
  /// Cleanup old video controllers to prevent memory leaks
  /// Only keep controllers for: previous reel, current reel, next reel
  void _cleanupOldControllers(int currentIndex, List<ReelModel> reels) {
    if (reels.isEmpty || _controllers.length <= 3) return;

    // Calculate indices with modulo for circular pagination
    final actualCurrentIndex = currentIndex % reels.length;
    final previousIndex = (actualCurrentIndex - 1 + reels.length) % reels.length;
    final nextIndex = (actualCurrentIndex + 1) % reels.length;

    // Get IDs to keep
    final idsToKeep = {
      reels[actualCurrentIndex].id,
      reels[previousIndex].id,
      reels[nextIndex].id,
    };

    // Dispose controllers not in the keep list
    final controllersToRemove = <String>[];
    _controllers.forEach((id, controller) {
      if (!idsToKeep.contains(id)) {
        controller.dispose();
        controllersToRemove.add(id);
      }
    });

    // Remove disposed controllers from map
    for (final id in controllersToRemove) {
      _controllers.remove(id);
    }

    if (controllersToRemove.isNotEmpty) {
      print('REELS_SCREEN: Cleaned up ${controllersToRemove.length} old controllers. Active: ${_controllers.length}');
    }
  }
'''

# Find the end of _onPageChanged method in _VideosViewState class
# Pattern: find the closing brace of _onPageChanged followed by empty lines and @override
pattern2 = r'(  void _onPageChanged\(int index, List<ReelModel> reels\) \{.*?^  \})\s+(\n\n  @override)'
replacement2 = r'\1' + cleanup_method + r'\2'
content = re.sub(pattern2, replacement2, content, flags=re.MULTILINE | re.DOTALL)

# Write back
with open(r'c:\Users\Vikas\AndroidStudioProjects\temple\lib\features\reels\presentation\screens\video_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Fix applied successfully!")

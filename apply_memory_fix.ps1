$filePath = "c:\Users\Vikas\AndroidStudioProjects\temple\lib\features\reels\presentation\screens\video_screen.dart"

# Read content
$content = Get-Content $filePath -Raw

# Step 1: Add cleanup call
$content = $content -replace '(setState\(\(\) \{\s+_currentIndex = index;\s+\}\);)\s+(// Pause previous video)', "`$1`r`n`r`n    // Cleanup old controllers to prevent memory leaks`r`n    _cleanupOldControllers(index, reels);`r`n`r`n    `$2"

# Step 2: Add cleanup method
$cleanupMethod = @'


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
'@

# Find location: after _onPageChanged closes, before @override in _VideosViewState
$pattern = '(      context\.read<ReelsProvider>\(\)\.incrementView\(reel\.id\);\s+}\s+}\s+)'
$replacement = "`$1$cleanupMethod`r`n"
$content = $content -replace $pattern, $replacement

# Save
Set-Content $filePath $content -NoNewline

Write-Host "✅ Memory fix applied successfully!"

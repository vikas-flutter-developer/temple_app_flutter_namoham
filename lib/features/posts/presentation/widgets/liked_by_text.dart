import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikedByText extends StatefulWidget {
  final List<String> likedBy;
  final List<String>? likedByNames;
  final int totalLikes;
  final ThemeData theme;

  const LikedByText({
    required this.likedBy,
    this.likedByNames,
    required this.totalLikes,
    required this.theme,
  });

  @override
  State<LikedByText> createState() => _LikedByTextState();
}

class _LikedByTextState extends State<LikedByText> {
  List<String> _resolvedNames = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _resolveNames();
  }

  @override
  void didUpdateWidget(covariant LikedByText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.likedBy != widget.likedBy || oldWidget.likedByNames != widget.likedByNames) {
      _resolveNames();
    }
  }

  void _resolveNames() async {
    // 1. Check if we already have names passed from parent
    if (widget.likedByNames != null && widget.likedByNames!.isNotEmpty) {
      if (mounted) {
        setState(() {
           _resolvedNames = widget.likedByNames!.take(2).toList();
        });
      }
      return;
    }

    // 2. If no names, but we have IDs, check if we need to fetch
    if (widget.likedBy.isEmpty) return;

    final idsToFetch = widget.likedBy.take(2).toList();
    
    // Start fetch
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    // Get current user info locally
    String? currentUserId;
    String? currentUserName;
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getString('user_id');
      currentUserName = prefs.getString('user_name') ?? prefs.getString('full_name');
    } catch (_) {}

    try {
      final api = ApiService.create();
      List<String> names = [];
      
      for (String id in idsToFetch) {
        // FAST PATH: Check if it's me!
        if (currentUserId != null && id == currentUserId) {
           // Always use "You" or specific name for the current user
           names.add(currentUserName ?? 'You');
           continue;
        }
      
        String? foundName;
        
        // Strategy: Try User -> Creator -> Temple
        
        // 1. Try User
        if (foundName == null) {
          try {
            final userMap = await api.getUserById(id);
            if (userMap.isNotEmpty) {
               // Try various fields
               foundName = userMap['username'] ?? 
                           userMap['name'] ?? 
                           userMap['fullName'] ?? 
                           userMap['full_name'] ??
                           userMap['firstName'];
                           
               // Check if it's nested in data/user (if api service missed it)
               if (foundName == null) {
                 if (userMap['data'] is Map) {
                    final d = userMap['data'];
                    foundName = d['username'] ?? d['name'] ?? d['fullName'];
                 } else if (userMap['user'] is Map) {
                    final u = userMap['user'];
                    foundName = u['username'] ?? u['name'] ?? u['fullName'];
                 }
               }
            }
          } catch (e) { 
             // print('LIKED_BY_DEBUG: User fetch failed: $e');
          }
        }
        
        // 2. Try Creator
        if (foundName == null) {
          try {
            final creator = await api.getCreatorById(id);
            foundName = creator.creatorName;
          } catch (_) { }
        }
        
        // 3. Try Temple
        if (foundName == null) {
          try {
             final temple = await api.getTempleById(id);
             foundName = temple.name;
          } catch (_) { }
        }
        
        if (foundName != null && foundName.isNotEmpty) {
          names.add(foundName);
        } else {
           // If we can't find the name, do NOT show "User". 
           // Better to show nothing for this slot and let the logic handle it.
           // Or if it's the ONLY liker, showing nothing means we fall back to "1 like".
           
           // DEBUG:
           print('LIKED_BY_DEBUG: Could not find name for ID: $id');
        }
      }
      
      if (mounted) {
        setState(() => _resolvedNames = names);
      }
    } catch (e) {
      print('Failed to resolve names: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalLikes == 0 && widget.likedBy.isEmpty) {
        return const SizedBox.shrink(); 
    }
    
    // Determine names to show. 
    // If we haven't resolved names yet, we should NOT show IDs. 
    // Maybe show nothing or "Loading..." or just the count.
    // Showing IDs is what the user hates.
    
    List<String> displayNames = _resolvedNames;
    
    // If still loading and no names, maybe return empty to show just "X likes"
    if (_isLoading && displayNames.isEmpty) {
       // Optional: Show nothing while loading (or skeleton)
       // Returning formatted text "X likes" is safer than showing IDs
       return Text(
        '${widget.totalLikes} likes',
        style: TextStyle(
          color: widget.theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (displayNames.isEmpty) {
        // Only show total count if no names resolved
       return Text(
        '${widget.totalLikes} likes',
        style: TextStyle(
          color: widget.theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    
    // Construct rich text
    // 1 Name: "Liked by Name1" OR "Liked by Name1 and X others"
    // 2 Names: "Liked by Name1, Name2" OR "Liked by Name1, Name2 and X others"
    
    String textContent = '';
    if (displayNames.length == 1) {
      textContent = displayNames[0];
    } else {
      textContent = displayNames.join(', ');
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: widget.theme.colorScheme.onSurface, fontSize: 13),
        children: [
          const TextSpan(text: 'Liked by '),
          TextSpan(
            text: textContent,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (widget.totalLikes > displayNames.length) ...[
            const TextSpan(text: ' and '),
            TextSpan(
              text: '${widget.totalLikes - displayNames.length} others',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

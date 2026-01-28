import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';

class CreatorCard extends StatefulWidget {
  final CreatorModel creator;
  final VoidCallback? onTap;

  const CreatorCard({
    super.key,
    required this.creator,
    required this.onTap,
  });

  @override
  State<CreatorCard> createState() => _CreatorCardState();
}

class _CreatorCardState extends State<CreatorCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        // Add constraints to control the size
        constraints: const BoxConstraints(maxWidth: 150, maxHeight: 350),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70, // Reduce size slightly
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(widget.creator.displayImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.creator.creatorName,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.creator.title,
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              height: 28,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero, // Allow smaller button size
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

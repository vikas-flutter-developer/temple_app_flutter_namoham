import 'package:flutter/material.dart';
import '../../features/profile/presentation/screens/following_page.dart'; // Import to access the FollowItem class

class FollowCard extends StatelessWidget {
  final FollowItem item;
  final VoidCallback? onToggleFollow; // Change callback name to reflect toggle

  const FollowCard({
    super.key,
    required this.item,
    this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFollowing = item.isFollowing; // Use property from item

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Image from network URL
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.image,
                width: 100,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 120,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      item.isPerson ? Icons.person : Icons.place,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Content on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: theme.colorScheme.primary, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people,
                              color: theme.colorScheme.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${item.followersCount} followers',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Additional details based on type
                  item.isPerson
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.username,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant, 
                              fontSize: 13,
                              fontStyle: FontStyle.italic
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            // Divider between properties
                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outlineVariant),
                            const SizedBox(height: 8),
                            // Rating and reviews
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.withOpacity(0.3))
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.rating.toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.amber[800]),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.reviews} reviews',
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

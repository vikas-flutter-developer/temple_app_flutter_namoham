import 'package:flutter/material.dart';
import '../../features/profile/presentation/screens/following_page.dart'; // Import to access the FollowItem class

class FollowCard extends StatelessWidget {
  final FollowItem item;
  final VoidCallback? onUnfollowPressed;

  const FollowCard({
    super.key,
    required this.item,
    this.onUnfollowPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(18),
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
                    width: 80,
                    height: 80,
                    color: theme.colorScheme.onSurface,
                    child: Icon(
                      item.isPerson ? Icons.person : Icons.place,
                      color: Colors.grey,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.grey, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.location,
                                    style: TextStyle(
                                        color: Colors.grey.shade600, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: onUnfollowPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(74, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Unfollow'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Additional details based on type
                  item.isPerson
                      ? Text(
                          item.username,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12), // Added top margin
                            // Distance
                            Text(
                              item.distance,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            // Divider between distance and rating
                            const Divider(height: 1, thickness: 0.5),
                            const SizedBox(height: 6),
                            // Rating and reviews
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.rating.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${item.reviews} reviews',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14),
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

// widgets/profile_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';

class ProfileHeader extends StatelessWidget {
  final TempleModel profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      //height: 300,
      child: Column(
        children: [
          // Background Image
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ClipRRect(
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: DecorationImage(
                    image: NetworkImage(profile.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Profile Info

          Padding(
            padding:
                const EdgeInsets.only(left: 20.0, right: 20, top: 5, bottom: 5),
            child: Container(
              color: theme.colorScheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${profile.rating} (${profile.totalReviews} Reviews)',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

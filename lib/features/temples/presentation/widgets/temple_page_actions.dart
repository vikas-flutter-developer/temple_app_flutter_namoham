// widgets/profile_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/donations/presentation/screens/make_donation_screen.dart';
import 'package:flutter_user_app/features/messages/presentation/screens/direct_chat_screen.dart';

import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';

class ProfileActions extends StatelessWidget {
  final TempleModel profile;

  const ProfileActions({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Consumer<FollowProvider>(
            builder: (context, followProvider, child) {
              if (!followProvider.canFollow) {
                return _buildButton(
                  text: 'Follow',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login as User to follow temples/creators'),
                      ),
                    );
                  },
                  context: context,
                );
              }

              final isFollowing = followProvider.isFollowing(profile.id);
              final label = isFollowing ? 'Unfollow' : 'Follow';

              return _buildButton(
                text: followProvider.isToggling ? '...' : label,
                onPressed: followProvider.isToggling
                    ? () {}
                    : () async {
                        final ok = isFollowing
                            ? await followProvider.unfollow(profile.id)
                            : await followProvider.follow(
                                followingId: profile.id,
                                followingType: 'temple',
                              );

                        // Refresh followers count so UI updates immediately
                        await followProvider.loadFollowers(profile.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? (isFollowing
                                        ? 'Unfollowed ${profile.name}'
                                        : 'Followed ${profile.name}')
                                    : (followProvider.error ?? 'Action failed'),
                              ),
                            ),
                          );
                        }
                      },
                context: context,
              );
            },
          ),
          SizedBox(width: 10),
          _buildButton(
            text: 'Message',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DirectChatEntry(
                    receiverId: profile.id,
                    receiverType: 'temple',
                    receiverName: profile.name,
                    receiverImage: profile.imageUrl,
                  ),
                ),
              );
            },
            context: context,
          ),
          SizedBox(width: 10),
          _buildButton(
              text: 'Donate',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MakeDonationScreen(
                      recipientId: profile.id,
                      recipientType: 'temple',
                      recipientName: profile.name,
                      recipientImage: profile.imageUrl,
                    ),
                  ),
                );
              },
              context: context),
        ],
      ),
    );
  }

  Widget _buildButton(
      {required String text,
      required VoidCallback onPressed,
      required BuildContext context}) {
    final theme = Theme.of(context);
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }
}

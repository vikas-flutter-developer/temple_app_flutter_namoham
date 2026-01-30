// widgets/profile_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Consumer<FollowProvider>(
            builder: (context, followProvider, child) {
              if (!followProvider.canFollow) {
                return _buildButton(
                  text: l10n.follow,
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
              final label = isFollowing ? l10n.unfollow : l10n.follow;

              return _buildButton(
                text: followProvider.isToggling ? '...' : label,
                onPressed: followProvider.isToggling
                    ? () {}
                    : () async {
                        print('TEMPLE_ACTIONS: Before follow - isFollowing: $isFollowing');
                        print('TEMPLE_ACTIONS: Temple ID: ${profile.id}');
                        
                        final ok = isFollowing
                            ? await followProvider.unfollow(
                                followingId: profile.id,
                                followingType: 'temple',
                              )
                            : await followProvider.follow(
                                followingId: profile.id,
                                followingType: 'Temple', // Capitalized
                              );

                        print('TEMPLE_ACTIONS: Follow API result: $ok');
                        print('TEMPLE_ACTIONS: After follow - isFollowing: ${followProvider.isFollowing(profile.id)}');
                        print('TEMPLE_ACTIONS: MyFollowing list length: ${followProvider.myFollowing.length}');
                        if (followProvider.myFollowing.isNotEmpty) {
                          print('TEMPLE_ACTIONS: First following ID: ${followProvider.myFollowing.first.followingId}');
                        }

                        // Reload follower count from API to get accurate data
                        await followProvider.loadFollowers(profile.id);
                        
                        print('TEMPLE_ACTIONS: Followers count: ${followProvider.followersCount}');

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? (isFollowing
                                        ? l10n.unfollowed(profile.name)
                                        : l10n.followed(profile.name))
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
            text: l10n.message,
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
              text: l10n.donate,
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

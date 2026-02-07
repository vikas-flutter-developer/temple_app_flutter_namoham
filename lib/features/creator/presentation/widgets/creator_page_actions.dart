// widgets/profile_actions.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';
import 'package:flutter_user_app/features/donations/presentation/screens/make_donation_screen.dart';
import 'package:flutter_user_app/features/messages/presentation/screens/direct_chat_screen.dart';

class CreatorProfileActions extends StatelessWidget {
  final CreatorModel profile;

  const CreatorProfileActions({super.key, required this.profile});

  Future<void> _launchMaps() async {
    // Use creator name for direction search
    final query = Uri.encodeComponent(profile.creatorName);
    final googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$query";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buttonColor = const Color(0xFF29D0FF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Follow/Unfollow Button
          Expanded(
            child: Consumer<FollowProvider>(
              builder: (context, followProvider, child) {
                if (!followProvider.canFollow) {
                  return _buildButton(
                    text: l10n.follow,
                    color: buttonColor,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Login as User to follow temples/creators'),
                        ),
                      );
                    },
                  );
                }

                final isFollowing = followProvider.isFollowing(profile.id);
                final label = isFollowing ? l10n.unfollow : l10n.follow;

                return _buildButton(
                  text: followProvider.isToggling ? '...' : label,
                  color: buttonColor,
                  isOutlined: isFollowing,
                  onPressed: followProvider.isToggling
                      ? () {}
                      : () async {
                          final ok = isFollowing
                              ? await followProvider.unfollow(
                                  followingId: profile.id,
                                  followingType: 'creator',
                                )
                              : await followProvider.follow(
                                  followingId: profile.id,
                                  followingType: 'Creator',
                                );

                          await followProvider.loadFollowers(profile.id);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? (isFollowing
                                          ? l10n.unfollowed(profile.creatorName)
                                          : l10n.followed(profile.creatorName))
                                      : (followProvider.error ?? 'Action failed'),
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                );
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Direction Button
          Expanded(
            child: _buildButton(
              text: 'Direction',
              color: buttonColor,
              onPressed: _launchMaps,
            ),
          ),

          const SizedBox(width: 8),

          // Donate Button
          Expanded(
            child: _buildButton(
              text: l10n.donate,
              color: buttonColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MakeDonationScreen(
                      recipientId: profile.id,
                      recipientType: 'creator',
                      recipientName: profile.creatorName,
                      recipientImage: profile.displayImage,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 8),

          // Message Button
          Expanded(
            child: _buildButton(
              text: l10n.message,
              color: buttonColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DirectChatEntry(
                      receiverId: profile.id,
                      receiverType: 'creator',
                      receiverName: profile.creatorName,
                      receiverImage: profile.displayImage,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.white : color,
          foregroundColor: isOutlined ? color : Colors.white,
          elevation: 0,
          side: isOutlined ? BorderSide(color: color) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

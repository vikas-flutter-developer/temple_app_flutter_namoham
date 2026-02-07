// widgets/profile_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/donations/presentation/screens/make_donation_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_user_app/features/messages/presentation/screens/direct_chat_screen.dart';

class ProfileActions extends StatelessWidget {
  final TempleModel profile;

  const ProfileActions({super.key, required this.profile});

  Future<void> _launchMaps() async {
    // Placeholder for direction logic. 
    // Ideally use coordinates from profile if available.
    final query = Uri.encodeComponent(profile.name);
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
    // Figma color (approximate from screenshot)
    final buttonColor = const Color(0xFF29D0FF); 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Follow Button
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
                    context: context,
                  );
                }

                final isFollowing = followProvider.isFollowing(profile.id);
                // "Follow" or "Unfollow" - keeping generic "Follow" style for now but text changes
                // Figma UI shows "Follow" in blue. Usually "Unfollow" is outlined or grey.
                // For "same to same" UI, if it's "Follow", it should be blue.
                final label = isFollowing ? l10n.unfollow : l10n.follow;

                return _buildButton(
                  text: followProvider.isToggling ? '...' : label,
                  color: buttonColor,
                  isOutlined: isFollowing, // Optional: differentiate visually
                  onPressed: followProvider.isToggling
                      ? () {}
                      : () async {
                          final ok = isFollowing
                              ? await followProvider.unfollow(
                                  followingId: profile.id,
                                  followingType: 'temple',
                                )
                              : await followProvider.follow(
                                  followingId: profile.id,
                                  followingType: 'Temple',
                                );

                          // Refresh
                          await followProvider.loadFollowers(profile.id);

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
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                  context: context,
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
              context: context,
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
                      recipientType: 'temple',
                      recipientName: profile.name,
                      recipientImage: profile.imageUrl,
                    ),
                  ),
                );
              },
              context: context,
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
                      receiverType: 'temple',
                      receiverName: profile.name,
                      receiverImage: profile.imageUrl,
                    ),
                  ),
                );
              },
              context: context,
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
    required BuildContext context,
    bool isOutlined = false,
  }) {
    // Style from Figma: Blue/Cyan background, White text, Rounded corners (approx 20-30px)
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
            borderRadius: BorderRadius.circular(24), // Rounded pill shape
          ),
          padding: EdgeInsets.zero, // Compact
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

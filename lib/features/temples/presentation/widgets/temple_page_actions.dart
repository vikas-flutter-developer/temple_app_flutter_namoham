// widgets/profile_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/donations/presentation/screens/make_donation_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_user_app/features/messages/presentation/screens/direct_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/messages/presentation/providers/messages_provider.dart';
import 'package:flutter_user_app/features/messages/presentation/screens/chat_screen.dart';

class ProfileActions extends StatelessWidget {
  final TempleModel profile;
  final bool isOwner;

  const ProfileActions({
    super.key, 
    required this.profile,
    this.isOwner = false,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
                          content: Text('Login as User or Creator to follow temples/creators'),
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
                  color: buttonColor,
                  isOutlined: isFollowing,
                  onPressed: followProvider.isToggling
                      ? () {}
                      : () async {
                          // Allow "Unfollow" even if it's your own account (though unlikely to be following yourself)
                          // But block "Follow" if it's your own account
                          if (isOwner && !isFollowing) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('You cannot follow your own account')),
                             );
                             return;
                          }

                          final ok = isFollowing
                              ? await followProvider.unfollow(
                                  followingId: profile.id,
                                  followingType: 'temple',
                                )
                              : await followProvider.follow(
                                  followingId: profile.id,
                                  followingType: 'Temple',
                                );

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
          
          const SizedBox(width: 8),
          
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
              color: const Color(0xFFFF9933),
              onPressed: () {
                if (isOwner) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You cannot donate to yourself')),
                  );
                  return;
                }
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
              onPressed: () async {
                if (isOwner) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('You cannot message yourself')),
                  );
                  return;
                }

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                // Create MessagesProvider instance
                final provider = MessagesProvider(ApiService.create());
                
                // Initiate or Find Chat
                final conversation = await provider.initiateChat(
                  otherUserId: profile.id,
                  otherUserType: 'temple',
                  otherUserName: profile.name,
                );

                // Dismiss loading
                if (context.mounted) Navigator.pop(context);

                if (conversation == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(provider.error ?? 'Failed to start chat')),
                    );
                  }
                  return;
                }

                // Check Status
                if (!context.mounted) return;

                if (conversation.status == 'accepted') {
                  // Open Chat Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: ChatScreen(conversation: conversation),
                      ),
                    ),
                  );
                } else if (conversation.status == 'pending') {
                   // Show Confirmation (Instagram Style)
                   showDialog(
                     context: context,
                     builder: (_) => AlertDialog(
                       title: const Text('Request Sent'),
                       content: Text(
                         'You have sent a message request to ${profile.name}. '
                         'You can chat once they accept your request.'
                       ),
                       actions: [
                         TextButton(
                           onPressed: () => Navigator.pop(context),
                           child: const Text('OK'),
                         ),
                       ],
                     ),
                   );
                } else if (conversation.status == 'rejected') {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Message request was declined.')),
                   );
                }
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
          backgroundColor: isOutlined ? Theme.of(context).colorScheme.surface : color,
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

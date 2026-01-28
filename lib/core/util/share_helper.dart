import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';

class ShareHelper {
  static final ApiService _apiService = ApiService.create();

  /// Show share options bottom sheet for a post
  static void showPostShareSheet(BuildContext context, String postId) {
    _showShareSheet(
      context: context,
      title: 'Share Post',
      onShare: (platform) => _sharePost(context, postId, platform),
    );
  }

  /// Show share options bottom sheet for a reel
  static void showReelShareSheet(BuildContext context, String reelId) {
    _showShareSheet(
      context: context,
      title: 'Share Reel',
      onShare: (platform) => _shareReel(context, reelId, platform),
    );
  }

  static void _showShareSheet({
    required BuildContext context,
    required String title,
    required Function(String platform) onShare,
  }) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);
                    onShare('whatsapp');
                  },
                ),
                _ShareOption(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(context);
                    onShare('facebook');
                  },
                ),
                _ShareOption(
                  icon: Icons.telegram,
                  label: 'Telegram',
                  color: const Color(0xFF0088CC),
                  onTap: () {
                    Navigator.pop(context);
                    onShare('telegram');
                  },
                ),
                _ShareOption(
                  icon: Icons.copy,
                  label: 'Copy Link',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onShare('copy');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  icon: Icons.camera_alt,
                  label: 'Instagram',
                  color: const Color(0xFFE4405F),
                  onTap: () {
                    Navigator.pop(context);
                    onShare('instagram');
                  },
                ),
                _ShareOption(
                  icon: Icons.alternate_email,
                  label: 'Twitter',
                  color: const Color(0xFF1DA1F2),
                  onTap: () {
                    Navigator.pop(context);
                    onShare('twitter');
                  },
                ),
                _ShareOption(
                  icon: Icons.more_horiz,
                  label: 'More',
                  color: theme.colorScheme.outline,
                  onTap: () {
                    Navigator.pop(context);
                    onShare('other');
                  },
                ),
                const SizedBox(width: 60), // Spacer for alignment
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Future<void> _sharePost(BuildContext context, String postId, String platform) async {
    try {
      final response = await _apiService.sharePost(postId, sharedVia: platform);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Post shared successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _shareReel(BuildContext context, String reelId, String platform) async {
    try {
      final response = await _apiService.shareReel(reelId, sharedVia: platform);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Reel shared successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

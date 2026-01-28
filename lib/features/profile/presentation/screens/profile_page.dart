import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/core/provider/theme_provider.dart';
import 'package:flutter_user_app/features/auth/register/presentation/screens/add_account_page.dart';

import 'package:flutter_user_app/features/profile/presentation/screens/contact_us_page.dart';
import 'package:flutter_user_app/features/creator/presentation/screens/creator_account_setup_screen.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/saved_post.dart';
import 'package:flutter_user_app/features/events/presentation/screens/events_screen.dart';
import 'package:flutter_user_app/features/messages/presentation/screens/conversations_screen.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_donation_screen.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_page_bar.dart';
import 'package:flutter_user_app/features/profile/presentation/widgets/profile_item_widget.dart';

import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/screens/following_list_screen.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_edit_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isDarkModeEnabled = true;
  String? _profilePhotoUrl;
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try to get photo URL from database first
    final photoUrl = prefs.getString('profile_photo_url');
    
    // Also get local cached path
    final localPath = prefs.getString('profile_photo_path');
    
    if (mounted) {
      setState(() {
        _profilePhotoUrl = photoUrl;
        _localPhotoPath = localPath;
      });
    }
  }

  Future<void> _showLogoutDialog() async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.logout, color: theme.colorScheme.error, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to logout from this account?',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true) {
      // Clear auth token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');

      // Navigate to login and clear stack
      if (mounted) {
        navigateToPageAndRemoveUntil(context, const LoginPage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomPageBar(title: "Profile"),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            // Profile Picture & Info
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: theme.colorScheme.primary, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: _profilePhotoUrl != null
                        ? Image.network(
                            _profilePhotoUrl!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              // If network image fails, try local file
                              if (_localPhotoPath != null) {
                                return Image.file(
                                  File(_localPhotoPath!),
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar(theme);
                                  },
                                );
                              }
                              return _buildDefaultAvatar(theme);
                            },
                          )
                        : _localPhotoPath != null
                            ? Image.file(
                                File(_localPhotoPath!),
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar(theme);
                                },
                              )
                            : _buildDefaultAvatar(theme),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hannah Turin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'madhuresh@gmail.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditScreen(),
                      ),
                    );
                    // Reload photo when returning from edit screen
                    _loadProfilePhoto();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),

            // Menu Sections
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh user profile data
                  setState(() {});
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                  const SizedBox(height: 18),

                  // GENERAL Section
                  _buildSectionHeader('GENERAL'),

                  // Profile Items
                  ProfileItemsWidget(
                    icon: Icons.people,
                    title: 'Following',
                    subtitle: 'Your following list',
                    onTap: () {
                      navigateToPage(context, const FollowingListScreen());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.bookmark,
                    title: 'Saved Post',
                    subtitle: 'Saved Photos, Videos',
                    onTap: () {
                      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: postsProvider,
                            child: const SavedPostScreen(),
                          ),
                        ),
                      );
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.message_outlined,
                    title: 'Messages',
                    subtitle: 'Chats & conversations',
                    onTap: () {
                      navigateToPage(context, const ConversationsScreen());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.event,
                    title: 'Events',
                    subtitle: 'View all events',
                    onTap: () {
                      navigateToPage(context, const EventsScreen());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.money,
                    title: 'Donation',
                    subtitle: 'Donation History',
                    onTap: () {
                      navigateToPage(context, DonationScreen());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.credit_card_outlined,
                    title: 'Bank Account',
                    subtitle: 'For recieve Donation',
                    onTap: () {
                      navigateToPage(context, const AddAccountPage());
                    },
                  ),

                  const SizedBox(height: 10),

                  // SETTINGS Section
                  _buildSectionHeader('SETTINGS'),
                  _buildDarkModeToggle(context),

                  ProfileItemsWidget(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'Select Your Favourite Language',
                    onTap: () {},
                  ),

                  const SizedBox(height: 10),

                  ProfileItemsWidget(
                    icon: Icons.person,
                    title: 'Switch To Creator ',
                    subtitle: 'Switch your account to creator',
                    onTap: () {
                      navigateToPage(context, const CreatorAccountSetupScreen());
                    },
                  ),

                  const SizedBox(height: 10),

                  // MORE Section
                  _buildSectionHeader('MORE'),



                  ProfileItemsWidget(
                    icon: Icons.phone,
                    title: 'Contact Us',
                    subtitle: 'For more information',
                    onTap: () {
                      navigateToPage(context, const ContactUs());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Logout from the current account',
                    onTap: _showLogoutDialog,
                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: 50,
        color: theme.colorScheme.outline,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final List<Map<String, dynamic>> themeModes = [
      {"label": "Light", "mode": ThemeMode.light},
      {"label": "Dark", "mode": ThemeMode.dark},
      {"label": "System", "mode": ThemeMode.system},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : themeProvider.themeMode == ThemeMode.light
                      ? Icons.light_mode_outlined
                      : Icons.brightness_auto,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Current: ${themeModes.firstWhere((item) => item["mode"] == themeProvider.themeMode)["label"]}',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  dropdownColor: theme.colorScheme.onInverseSurface,
                  borderRadius: BorderRadius.circular(10),
                  items:
                      themeModes.map<DropdownMenuItem<ThemeMode>>((themeMode) {
                    return DropdownMenuItem<ThemeMode>(
                      value: themeMode['mode'] as ThemeMode,
                      child: Text(
                        themeMode['label'] as String,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (ThemeMode? newMode) {
                    if (newMode != null) {
                      themeProvider.setThemeMode(newMode);
                    }
                  },
                  icon: Icon(Icons.arrow_drop_down,
                      color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

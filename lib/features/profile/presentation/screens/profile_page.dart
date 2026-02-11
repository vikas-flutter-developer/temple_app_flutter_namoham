import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/core/provider/theme_provider.dart';
import 'package:flutter_user_app/features/auth/register/presentation/screens/add_account_page.dart';
import 'package:flutter_user_app/core/api/api_service.dart'; // Import ApiService

import 'package:flutter_user_app/features/profile/presentation/screens/contact_us_page.dart';
import 'package:flutter_user_app/features/settings/presentation/screens/language_screen.dart';
import 'package:flutter_user_app/features/creator/presentation/screens/creator_account_setup_screen.dart';
import 'package:flutter_user_app/features/auth/login/presentation/screens/login_page.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/saved_post.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/terms_conditions_screen.dart';
import 'package:flutter_user_app/features/events/presentation/screens/events_screen.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';
import 'package:flutter_user_app/features/messages/presentation/screens/conversations_screen.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_donation_screen.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_page_bar.dart';
import 'package:flutter_user_app/features/profile/presentation/widgets/profile_item_widget.dart';

import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/screens/following_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_user_app/features/app_ratings/presentation/screens/app_rating_screen.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/request_delete_account_screen.dart';
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
  String _fullName = '';
  String _userType = 'user';
  String _email = '';
  bool _isLoading = true;
  String _appVersion = '';
  final ApiService _apiService = ApiService.create();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      print('APP_VERSION: ${packageInfo.version}');
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version.isNotEmpty ? packageInfo.version : '0.1.0';
        });
      }
    } catch (e) {
      print('Error loading app version: $e');
      if (mounted) {
        setState(() {
          _appVersion = '0.1.0'; // Fallback version
        });
      }
    }
  }

  void _showComingSoonToast() {
    Fluttertoast.showToast(
      msg: "Coming Soon",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load local cached data first for immediate display
    if (mounted) {
      setState(() {
        _profilePhotoUrl = prefs.getString('profile_photo_url');
        _localPhotoPath = prefs.getString('profile_photo_path');
        _fullName = prefs.getString('full_name') ?? '';
        _email = prefs.getString('email') ?? '';
        _userType = prefs.getString('user_type') ?? 'user';
      });
    }

    // Then fetch fresh data from API
    try {
      final userId = prefs.getString('user_id');
      final userType = prefs.getString('user_type');

      if (userId == null) return;

      Map<String, dynamic>? fetchedData;
      String? newName;
      String? newEmail;
      String? newPhoto;

      if (userType == 'user' || userType == 'User') {
        try {
          final userData = await _apiService.getUserById(userId);
          newName = userData['name'] ?? userData['fullName'];
          newEmail = userData['email'];
          newPhoto = userData['profilePic'] ?? userData['userImage'] ?? userData['imageUrl'] ?? userData['image'] ?? userData['profileImage'];
        } catch (e) {
          debugPrint('User profile API fetch failed, using local data: $e');
        }
      } else if (userType == 'temple' || userType == 'Temple') {
        final temple = await _apiService.getTempleById(userId);
        newName = temple.name;
        newEmail = temple.email;
        newPhoto = temple.imageUrl;
      } else if (userType == 'creator' || userType == 'Creator') {
        final creator = await _apiService.getCreatorById(userId);
        newName = creator.creatorName;
        newEmail = creator.email;
        newPhoto = creator.profilePic;
      }

      if (newName != null) {
        // Update local storage
        await prefs.setString('full_name', newName);
        if (newEmail != null) await prefs.setString('email', newEmail);
        if (newPhoto != null) await prefs.setString('profile_photo_url', newPhoto);

        if (mounted) {
           setState(() {
             _fullName = newName!;
             if (newEmail != null) _email = newEmail!;
             if (newPhoto != null) _profilePhotoUrl = newPhoto!;
             _isLoading = false;
           });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
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
      // Clear all stored data (auth token, profile info, etc.) to prevent mix-ups
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to login and clear stack
      if (mounted) {
        navigateToPageAndRemoveUntil(context, const LoginPage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    // Check types
    final isUser = _userType.toLowerCase() == 'user';
    final isTemple = _userType.toLowerCase() == 'temple';
    final isCreator = _userType.toLowerCase() == 'creator';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomPageBar(title: l10n.profile),
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
                        ? CustomNetworkImage(
                            imageUrl: _profilePhotoUrl!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorWidget: _localPhotoPath != null
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
                const SizedBox(height: 10),
                Text(
                  _fullName.isNotEmpty ? _fullName : 'Guest User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _email.isNotEmpty ? _email : '',
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
                    // Reload profile when returning from edit screen
                    _loadProfileData();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: Text(
                    l10n.edit,
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
                  await _loadProfileData();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                  const SizedBox(height: 18),

                  // GENERAL Section
                  _buildSectionHeader(l10n.general),

                  // Profile Items
                  ProfileItemsWidget(
                    icon: Icons.people,
                    title: l10n.following,
                    subtitle: l10n.yourFollowingList,
                    onTap: () {
                      navigateToPage(context, const FollowingListScreen());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.bookmark,
                    title: l10n.savedPost,
                    subtitle: l10n.savedPhotosVideos,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedPostScreen(),
                        ),
                      );
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.message_outlined,
                    title: l10n.messages,
                    subtitle: l10n.chatsConversations,
                    onTap: () {
                      navigateToPage(context, const ConversationsScreen());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.event,
                    title: l10n.events,
                    subtitle: l10n.viewAllEvents,
                    onTap: () {
                      navigateToPage(context, const EventsScreen());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.money,
                    title: l10n.donation,
                    subtitle: l10n.donationHistory,
                    onTap: () {
                      navigateToPage(context, DonationScreen());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.alarm,
                    title: 'Event Reminder',
                    subtitle: 'Saved Events For Reminder',
                    onTap: _showComingSoonToast,
                  ),

                  if (isTemple || isCreator)
                    ProfileItemsWidget(
                      icon: Icons.credit_card_outlined,
                      title: l10n.bankAccount,
                      subtitle: l10n.forReceiveDonation,
                      onTap: () {
                        navigateToPage(context, const AddAccountPage());
                      },
                    ),

                  const SizedBox(height: 10),

                  // SETTINGS Section
                  _buildSectionHeader(l10n.settings),
                  _buildDarkModeToggle(context),

                  ProfileItemsWidget(
                    icon: Icons.language,
                    title: l10n.language,
                    subtitle: l10n.selectYourFavouriteLanguage,
                    onTap: () {
                      navigateToPage(context, const LanguageScreen());
                    },
                  ),

                  const SizedBox(height: 10),

                  if (isUser)
                    ProfileItemsWidget(
                      icon: Icons.person,
                      title: l10n.switchToCreator,
                      subtitle: l10n.switchYourAccountToCreator,
                      onTap: () {
                        navigateToPage(context, const CreatorAccountSetupScreen());
                      },
                    ),

                  const SizedBox(height: 10),

                  // MORE Section
                  _buildSectionHeader(l10n.more),

                  ProfileItemsWidget(
                    icon: Icons.phone,
                    title: l10n.contactUs,
                    subtitle: l10n.forMoreInformation,
                    onTap: () {
                      navigateToPage(context, const ContactUs());
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently Delete Your Account',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RequestDeleteAccountScreen(),
                        ),
                      );
                    },
                  ),

                  ProfileItemsWidget(
                    icon: Icons.logout,
                    title: l10n.logout,
                    subtitle: l10n.logoutFromCurrentAccount,
                    onTap: _showLogoutDialog,
                  ),

                  const SizedBox(height: 24),

                  // Footer section with Share, Rate, Privacy, Terms, and Version
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: _showComingSoonToast,
                              child: Text(
                                'Share Us',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              height: 12,
                              width: 1,
                              color: theme.colorScheme.outline,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AppRatingScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Rate Us',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              height: 12,
                              width: 1,
                              color: theme.colorScheme.outline,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsAndConditionsScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Terms & Conditions',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              height: 12,
                              width: 1,
                              color: theme.colorScheme.outline,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'App Version: $_appVersion',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
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

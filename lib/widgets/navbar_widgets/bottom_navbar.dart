import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';

class CustomBottomNav extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabChange;
  final PageController pageController;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
    required this.pageController,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  void _onItemTapped(int index) {
    widget.onTabChange(index);
    widget.pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isReels = widget.selectedIndex == 2;
    
    return Container(
      color: isReels ? Colors.transparent : theme.colorScheme.surface,
      child: SafeArea(
        child: Material(
          color: Colors.transparent, // Important for transparency
          child: Container(
            height: 65,
            margin: isReels ? const EdgeInsets.only(bottom: 8, left: 10, right: 10) : null,
            decoration: BoxDecoration(
              color: isReels ? Colors.black.withOpacity(0.3) : theme.colorScheme.surface,
              borderRadius: isReels ? BorderRadius.circular(30) : null,
            border: isReels ? null : Border(
              top: BorderSide(
                color: theme.colorScheme.outline,
                width: 0.1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: GNav(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              rippleColor: isReels ? Colors.white.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1),
              gap: 8,
              activeColor: isReels ? Colors.white : theme.colorScheme.primary,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: isReels 
                  ? Colors.white.withOpacity(0.2) 
                  : theme.colorScheme.secondaryContainer.withOpacity(0.3),
              color: isReels ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.8),
              textStyle: TextStyle(
                color: isReels ? Colors.white : theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              haptic: true,
              tabs: [
                GButton(
                  icon: Icons.home,
                  text: l10n.home,
                  leading: SvgPicture.asset(
                    widget.selectedIndex == 0
                        ? 'assets/icons_bottomnav/home_filled.svg'
                        : 'assets/icons_bottomnav/home.svg',
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      widget.selectedIndex == 0
                          ? (isReels ? Colors.white : theme.colorScheme.primary)
                          : (isReels ? Colors.white : theme.colorScheme.onSurface),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                GButton(
                  icon: Icons.search,
                  text: l10n.search,
                  leading: SvgPicture.asset(
                    widget.selectedIndex == 1
                        ? 'assets/icons_bottomnav/search_filled.svg'
                        : 'assets/icons_bottomnav/search.svg',
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      widget.selectedIndex == 1
                          ? (isReels ? Colors.white : theme.colorScheme.primary)
                          : (isReels ? Colors.white : theme.colorScheme.onSurface),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                GButton(
                  icon: Icons.video_file,
                  text: l10n.reels,
                  leading: SvgPicture.asset(
                    widget.selectedIndex == 2
                        ? 'assets/icons_bottomnav/video_filled.svg'
                        : 'assets/icons_bottomnav/video.svg',
                    height: 25,
                    colorFilter: ColorFilter.mode(
                      widget.selectedIndex == 2
                          ? (isReels ? Colors.white : theme.colorScheme.primary)
                          : (isReels ? Colors.white : theme.colorScheme.onSurface),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                GButton(
                  icon: Icons.person,
                  text: l10n.profile,
                  leading: SvgPicture.asset(
                    widget.selectedIndex == 3
                        ? 'assets/icons_bottomnav/profile_filled.svg'
                        : 'assets/icons_bottomnav/profile.svg',
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      widget.selectedIndex == 3
                          ? (isReels ? Colors.white : theme.colorScheme.primary)
                          : (isReels ? Colors.white : theme.colorScheme.onSurface),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
              selectedIndex: widget.selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    ),
  );
}
}

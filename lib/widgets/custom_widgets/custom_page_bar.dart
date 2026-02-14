import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/messages/presentation/screens/conversations_screen.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:provider/provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';

class CustomPageBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  const CustomPageBar({super.key, required this.title});

  @override
  State<CustomPageBar> createState() => _CustomPageBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomPageBarState extends State<CustomPageBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.2),
      forceMaterialTransparency: true,
      title: Center(
        child: Text(
          widget.title,
          style: TextStyle(
            fontSize: 24,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      leadingWidth: 65,
      leading: IconButton(
        icon: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryFixed,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SvgPicture.asset('assets/icons/menu.svg',
                colorFilter: ColorFilter.mode(
                    theme.colorScheme.onPrimaryFixed, BlendMode.srcIn)),
          ),
        ),
        onPressed: () {},
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final unreadCount = notificationProvider.unreadCount;
            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryFixed,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(9.0),
                      child: SvgPicture.asset('assets/icons/notification.svg',
                          colorFilter: ColorFilter.mode(
                              theme.colorScheme.onPrimaryFixed, BlendMode.srcIn)),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                navigateToPage(context, const NotificationScreen());
              },
            );
          },
        ),
        const SizedBox(width: 5),
      ],
    );
  }
}

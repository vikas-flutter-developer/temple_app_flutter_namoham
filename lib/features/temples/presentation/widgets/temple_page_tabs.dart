// widgets/profile_tabs.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/temples/data/models/review_model.dart';

import 'package:flutter_user_app/features/temples/presentation/tabs/temple_about_tab.dart';
import 'package:flutter_user_app/features/temples/presentation/tabs/temple_calender_tab.dart';
import 'package:flutter_user_app/features/temples/presentation/tabs/temple_gallery_tab.dart';
import 'package:flutter_user_app/features/temples/presentation/tabs/temple_review_tab.dart';

class ProfileTabs extends StatelessWidget {
  final TabController tabController;
  final TempleModel profile;

  const ProfileTabs({
    super.key,
    required this.tabController,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: Column(
        children: [
          TabBar(
            controller: tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.outline,
            indicatorColor: theme.colorScheme.primary,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: l10n.about),
              Tab(text: l10n.review),
              Tab(text: l10n.gallery),
              Tab(text: l10n.calendar),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                AboutTab(profile: profile),
                ReviewTab(
                  reviews: profile.reviews,
                  temple: profile,
                ),
                GalleryTab(templeId: profile.id, templeName: profile.name),
                CalendarTab(templeId: profile.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

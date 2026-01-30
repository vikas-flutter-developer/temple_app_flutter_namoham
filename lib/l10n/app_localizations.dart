import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @yourFollowingList.
  ///
  /// In en, this message translates to:
  /// **'Your following list'**
  String get yourFollowingList;

  /// No description provided for @savedPost.
  ///
  /// In en, this message translates to:
  /// **'Saved Post'**
  String get savedPost;

  /// No description provided for @savedPhotosVideos.
  ///
  /// In en, this message translates to:
  /// **'Saved Photos, Videos'**
  String get savedPhotosVideos;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @chatsConversations.
  ///
  /// In en, this message translates to:
  /// **'Chats & conversations'**
  String get chatsConversations;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @viewAllEvents.
  ///
  /// In en, this message translates to:
  /// **'View all events'**
  String get viewAllEvents;

  /// No description provided for @donation.
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get donation;

  /// No description provided for @donationHistory.
  ///
  /// In en, this message translates to:
  /// **'Donation History'**
  String get donationHistory;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// No description provided for @forReceiveDonation.
  ///
  /// In en, this message translates to:
  /// **'For recieve Donation'**
  String get forReceiveDonation;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @currentSystem.
  ///
  /// In en, this message translates to:
  /// **'Current: System'**
  String get currentSystem;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectYourFavouriteLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Your Favourite Language'**
  String get selectYourFavouriteLanguage;

  /// No description provided for @switchToCreator.
  ///
  /// In en, this message translates to:
  /// **'Switch To Creator'**
  String get switchToCreator;

  /// No description provided for @switchYourAccountToCreator.
  ///
  /// In en, this message translates to:
  /// **'Switch your account to creator'**
  String get switchYourAccountToCreator;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'MORE'**
  String get more;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @forMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'For more information'**
  String get forMoreInformation;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutFromCurrentAccount.
  ///
  /// In en, this message translates to:
  /// **'Logout from the current account'**
  String get logoutFromCurrentAccount;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @donate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @followersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} followers'**
  String followersCount(int count);

  /// No description provided for @searchTemples.
  ///
  /// In en, this message translates to:
  /// **'Search temples...'**
  String get searchTemples;

  /// No description provided for @searchCreators.
  ///
  /// In en, this message translates to:
  /// **'Search creators...'**
  String get searchCreators;

  /// No description provided for @searchAll.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchAll;

  /// No description provided for @allTemples.
  ///
  /// In en, this message translates to:
  /// **'All Temples'**
  String get allTemples;

  /// No description provided for @allCreators.
  ///
  /// In en, this message translates to:
  /// **'All Creators'**
  String get allCreators;

  /// No description provided for @foundResults.
  ///
  /// In en, this message translates to:
  /// **'Found {count} results'**
  String foundResults(int count);

  /// No description provided for @temples.
  ///
  /// In en, this message translates to:
  /// **'Temples'**
  String get temples;

  /// No description provided for @templesCount.
  ///
  /// In en, this message translates to:
  /// **'Temples: {count}'**
  String templesCount(int count);

  /// No description provided for @creators.
  ///
  /// In en, this message translates to:
  /// **'Creators'**
  String get creators;

  /// No description provided for @creatorsCount.
  ///
  /// In en, this message translates to:
  /// **'Creators: {count}'**
  String creatorsCount(int count);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviews;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @followed.
  ///
  /// In en, this message translates to:
  /// **'Followed {name}'**
  String followed(String name);

  /// No description provided for @unfollowed.
  ///
  /// In en, this message translates to:
  /// **'Unfollowed {name}'**
  String unfollowed(String name);

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get general;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी (Marathi)'**
  String get marathi;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी (Hindi)'**
  String get hindi;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી (Gujarati)'**
  String get gujarati;

  /// No description provided for @mostPopularTemple.
  ///
  /// In en, this message translates to:
  /// **'Most Popular Temple'**
  String get mostPopularTemple;

  /// No description provided for @mostPopularCreator.
  ///
  /// In en, this message translates to:
  /// **'Most Popular Creator'**
  String get mostPopularCreator;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noTemplesFound.
  ///
  /// In en, this message translates to:
  /// **'No temples found'**
  String get noTemplesFound;

  /// No description provided for @noCreatorsFound.
  ///
  /// In en, this message translates to:
  /// **'No creators found'**
  String get noCreatorsFound;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search Temples & Creators...'**
  String get searchPlaceholder;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noFollowersYet.
  ///
  /// In en, this message translates to:
  /// **'No followers yet.'**
  String get noFollowersYet;

  /// No description provided for @noFollowingYet.
  ///
  /// In en, this message translates to:
  /// **'You are not following anyone yet.'**
  String get noFollowingYet;

  /// No description provided for @onlyUsersHaveFollowingList.
  ///
  /// In en, this message translates to:
  /// **'Only users have a following list.'**
  String get onlyUsersHaveFollowingList;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

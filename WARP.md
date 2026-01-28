# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview
A Flutter mobile application for temple management and spiritual content, supporting three user types: regular users, temples, and creators. The app features posts/reels, temple/creator profiles, donations, and social interactions.

**Package name**: `flutter_user_app`

## Development Commands

### Running the App
```powershell
# Run on connected device/emulator
flutter run

# Run with specific device
flutter devices  # List available devices
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

### Testing
```powershell
# Run all tests (note: test directory is currently empty)
flutter test

# Run specific test file
flutter test test/<path_to_test_file>
```

### Code Quality
```powershell
# Analyze code for issues
flutter analyze

# Check formatting
dart format --output=none --set-exit-if-changed .

# Format all Dart files
dart format .
```

### Building
```powershell
# Build APK
flutter build apk

# Build app bundle (for Play Store)
flutter build appbundle

# Build for Windows
flutter build windows
```

### Dependencies
```powershell
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Clear build cache
flutter clean
```

## Architecture

### Project Structure
The app follows **Clean Architecture** principles with feature-based organization:

```
lib/
├── core/                    # Shared utilities across features
│   ├── api/                 # ApiService - centralized HTTP client
│   ├── config/              # Constants and configuration
│   ├── helper/              # Navigation helpers
│   ├── provider/            # Global providers (theme)
│   └── util/                # Theme schemes
├── features/                # Feature modules
│   ├── auth/                # Authentication (login, register)
│   ├── home/                # Home screen with PageView navigation
│   ├── posts/               # Posts feature with clean architecture layers
│   │   ├── data/            # Models, repositories implementation, dummy data
│   │   ├── domain/          # Entities, repository contracts, use cases
│   │   └── presentation/    # Screens, widgets, providers
│   ├── reels/               # Video reels feature
│   ├── search/              # Search functionality
│   ├── profile/             # User profile and settings
│   ├── temples/             # Temple profiles, events, donations
│   ├── creator/             # Creator profiles and content
│   └── add_post/            # Post creation with image cropping
├── widgets/                 # Reusable UI components
│   ├── card_widgets/        # Custom cards
│   ├── custom_widgets/      # Buttons, text fields, etc.
│   └── navbar_widgets/      # Bottom navigation bar
└── main.dart                # App entry point
```

### Key Architectural Patterns

#### 1. Clean Architecture (Posts Feature)
The posts feature demonstrates the clean architecture pattern:
- **Domain Layer**: Entities (`PostEntity`, `PostCommentEntity`) and use cases
- **Data Layer**: Models, repositories, and dummy data
- **Presentation Layer**: Screens, widgets, and providers

Other features use a simplified architecture without the domain/data separation.

#### 2. State Management: Provider
- Uses the `provider` package for state management
- Key providers:
  - `ThemeProvider`: Manages theme mode (light/dark) with persistent storage
  - `PostsProvider`: Manages posts state (loading, loaded, error)
  - `CommentProvider`: Manages comment state
- Pattern: `ChangeNotifier` with status enums (`PostsStatus`, etc.)

#### 3. Navigation Pattern
The app uses a custom navigation helper (`core/helper/navigation_helper.dart`):
- `navigateToPage()`: Standard push navigation
- `navigateToPageReplacement()`: Replace current route
- `navigateToPageAndRemoveUntil()`: Clear navigation stack (used for login/logout)

#### 4. API Service
Centralized HTTP client in `core/api/api_service.dart`:
- Base URL: `https://temple-backend.el.r.appspot.com/api`
- Handles authentication, posts, and comments
- Returns `Future<Map<String, dynamic>>` or throws exceptions

## Critical Business Rules

### Authentication Flow
**IMPORTANT**: After successful login, users CANNOT use the back button to return to the login page.

1. **Login Navigation**: Must use `navigateToPageAndRemoveUntil()` when navigating from LoginPage to HomePage
   - This clears the entire navigation stack
   - Already implemented in `login_page.dart:97`

2. **Logout Flow**: Users can only return to login by explicitly logging out
   - Logout action shows a confirmation dialog: "Do you want to logout?"
   - After confirmation, clears auth token and uses `navigateToPageAndRemoveUntil()` to return to LoginPage
   - Implemented in both `profile_page.dart` (logout button) and `home_page.dart` (back button handler)

3. **HomePage Back Button**: Uses `PopScope` to intercept back button and show logout confirmation
   - When user presses back button on HomePage, shows "Do you want to logout?" dialog
   - Prevents accidental app exit or return to login screen

### User Types
The app supports three distinct user types with separate login flows:
- **User Login**: Regular users (default test: `raj.kumar@example.com` / `User@123456`)
- **Temple Login**: Temple administrators (test: `golden@example.com` / `Temple@123`)
- **Creator Login**: Content creators (test: `swami@example.com` / `Creator@123`)

Auto-fill credentials are provided in login screen for development/testing.

## Technical Details

### Theme System
- Uses `flex_color_scheme` package for theming
- Supports light/dark mode with system preference option
- Theme persisted using `shared_preferences`
- System UI (status bar, navigation bar) updates dynamically with theme

### Assets Structure
```
assets/
├── splash/              # App splash screen images
├── illustrations/       # SVG illustrations
├── icons/               # General icons
├── icons_bottomnav/     # Bottom navigation icons (filled/outlined states)
├── contact_icons/       # Contact-related icons
├── video/               # Video assets
└── lottie/              # Lottie animations
```

### Authentication Token Storage
- Tokens stored in `shared_preferences` with key `'auth_token'`
- Set on login: `await prefs.setString('auth_token', token);`
- **Note**: Token is not currently used for authenticated requests

### Common Patterns

#### Custom Widgets
- `CustomTextField`: Standard input field with label
- `CustomButton`: Primary action button
- `CustomPageBar`: Consistent app bar across screens
- `CustomBottomNav`: Bottom navigation with Google Nav Bar

#### Image Handling
- Uses `image_picker` for selecting images
- Custom crop functionality in `add_post/presentation/screens/crop_page.dart`
- Network images with circular clipping for avatars

#### Video Player
- Uses `video_player` package
- Modified video player widget in `reels/presentation/widgets/modified_reel_video.dart`

## Dependencies to Know

### Core Flutter Packages
- `provider: ^6.1.2` - State management
- `http: ^1.2.0` - API calls
- `shared_preferences: ^2.5.2` - Local storage

### UI/UX Packages
- `flex_color_scheme: ^8.1.1` - Theming
- `google_nav_bar: ^5.0.7` - Bottom navigation
- `flutter_svg: ^2.0.17` - SVG support
- `lottie: ^3.3.1` - Animations
- `smooth_page_indicator: ^1.2.1` - Page indicators

### Functional Packages
- `dartz: ^0.10.1` - Functional programming (Either type)
- `equatable: ^2.0.7` - Value equality
- `intl: ^0.20.2` - Internationalization

### Feature-Specific
- `camera: ^0.10.5+9` / `image_picker: ^1.0.4` - Media capture
- `video_player: ^2.7.0` - Video playback
- `country_picker: ^2.0.27` - Country selection
- `table_calendar: ^3.2.0` - Calendar widget
- `like_button: ^2.0.5` - Like animations

## Development Notes

### Current State
- No test files currently exist in the `test/` directory
- Some features use clean architecture (posts), others use simplified architecture
- Dummy data provided for development in `data/dummy/` directories
- API integration in progress - some features may use mock data

### When Adding Features
1. Follow the feature-based structure under `lib/features/`
2. For complex features, use clean architecture layers (domain/data/presentation)
3. For simple features, direct presentation layer is acceptable
4. Use `Provider` for state management with status enums
5. Reuse widgets from `lib/widgets/` when possible
6. Add navigation using helpers from `core/helper/navigation_helper.dart`

### When Modifying Authentication
- Always use `navigateToPageAndRemoveUntil()` for login/logout transitions
- Implement logout confirmation dialog before navigation
- Store/clear auth tokens in SharedPreferences
- Remember the three user types system

### When Working with API
- All HTTP calls go through `ApiService` in `core/api/api_service.dart`
- API returns `Map<String, dynamic>` or throws exceptions
- Models in data layer convert API responses to entities
- Use try-catch blocks for error handling with user-friendly messages

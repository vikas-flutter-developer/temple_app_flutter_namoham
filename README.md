# Temple Mobile App

A feature-rich Flutter application designed to connect devotees with Temples and Content Creators. This app provides a social platform for spiritual content, temple management, and community engagement.

## 🚀 Key Features

*   **Authentication & User Management**
    *   Secure Login & Registration via Email/OTP.
    *   Role-based access (User, Temple Admin, Creator).
    *   Profile management and customization.

*   **Social & Community**
    *   **Feeds**: Explore Posts and Reels from temples and creators.
    *   **Interaction**: Like, Comment, Share, and Save posts.
    *   **Follow System**: Follow your favorite temples and creators to stay updated.
    *   **Messaging**: Direct messaging capabilities.

*   **Temple Services**
    *   **Discovery**: Search and explore temples.
    *   **Donations**: Secure donation processing for temples and creators.
    *   **Events**: View and participate in temple events.
    *   **Gallery**: Browse photos and videos.

*   **Multimedia**
    *   Short video Reels integration.
    *   Image and Video upload capabilities.
    *   Supabase integration for media storage.

## 🛠️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/) (Dart)
*   **State Management**: [Provider](https://pub.dev/packages/provider)
*   **Networking**: `http` package with custom API service.
*   **Storage**: Shared Preferences (local), Supabase (Cloud Storage).
*   **UI/UX**: Custom themed widgets, `flutter_svg`, `lottie` animations, `google_nav_bar`.

## ⚙️ Setup & Installation

1.  **Prerequisites**
    *   Flutter SDK installed (Version 3.6.0 or higher recommended).
    *   Android Studio / VS Code with Flutter extensions.

2.  **Clone the Repository**
    ```bash
    git clone https://github.com/abhitreader-hub/temple-mobile-frontend.git
    cd temple-mobile-frontend
    ```

3.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

4.  **Environment Configuration**
    *   Create a `.env` file in the root directory.
    *   Copy the contents from `.env.example` and fill in your API keys.
    ```env
    BASE_URL=https://your-api-url.com/api
    SUPABASE_URL=https://your-project.supabase.co
    SUPABASE_ANON_KEY=your_key
    # ... other keys
    ```

5.  **Run the App**
    ```bash
    flutter run
    ```

## 📁 Project Structure

The project follows a Feature-First architecture:
- `lib/core`: Shared components, configuration, network services, and utilities.
- `lib/features`: Distinct modules for each feature (Auth, Home, Posts, Profile, etc.), containing their own Presentation, Data, and Domain layers.
- `lib/widgets`: Reusable global UI widgets.

## 🤝 Contributing

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

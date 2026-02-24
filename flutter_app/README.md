# House Expense Manager - Flutter App

A cross-platform mobile application for tracking shared house expenses, built with Flutter.

## Features

- **User Authentication**: Secure login with JWT tokens
- **Dashboard**: View personal balance and expense summary
- **Invoice Management**: Create and manage shared expense invoices
- **Expense Splitting**: Automatic calculation of who owes what
- **Admin Panel**: User management and invoice controls (admin only)
- **Undo Functionality**: 10-second undo window for deletions
- **Offline Support**: Automatic session persistence

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Android Studio / Xcode (for emulators)
- Backend server running (see backend README)

### Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   
   For Android emulator:
   ```bash
   flutter run
   ```
   
   For web:
   ```bash
   flutter run -d chrome
   ```

### Configuration

The app automatically detects the platform and sets the appropriate API URL:
- **Android Emulator**: `http://10.0.2.2:3000`
- **iOS Simulator**: `http://localhost:3000`
- **Web**: Relative path (same origin)

To change the backend URL, edit `lib/services/api_service.dart`.

## Default Login

- **Name**: Omar
- **Password**: admin123

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── item.dart
│   ├── invoice.dart
│   └── balance.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── invoice_provider.dart
│   ├── balance_provider.dart
│   └── item_provider.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── invoices_screen.dart
│   ├── add_invoice_screen.dart
│   └── admin_screen.dart
├── services/                 # API services
│   └── api_service.dart
└── utils/                    # Utilities
    └── theme.dart
```

## License

MIT

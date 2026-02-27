# Note App

A beautiful and intuitive cross-platform note-taking application built with Flutter. Create, organize, and manage your notes with ease using an inspiring staggered grid layout.

## Features

✨ **Core Features:**
- 📝 Create, edit, and delete notes
- 🎨 Clean and intuitive user interface
- 📱 Staggered grid layout for better note visualization
- 🖼️ Image support - attach images to your notes
- 🔒 Local storage - all your notes are saved locally
- ⚙️ User preferences - customizable app settings
- 🌍 Cross-platform support (Android, iOS, macOS, Windows, Linux, Web)

## System Requirements

- **Flutter SDK:** ^3.10.7 or higher
- **Dart SDK:** Latest version compatible with Flutter
- **Android:** API level 21 or higher
- **iOS:** iOS 11.0 or higher
- **Java Development Kit (JDK):** 11 or higher (for Android development)

## Installation & Setup

### 1. Prerequisites
Ensure you have Flutter installed on your system. If not, follow the [official Flutter installation guide](https://flutter.dev/docs/get-started/install).

### 2. Clone or Download the Project
```bash
git clone <repository-url>
cd note_app
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the App

**For Android:**
```bash
flutter run
```

**For iOS:**
```bash
flutter run -d ios
```

**For Web:**
```bash
flutter run -d web
```

**For Windows/macOS/Linux:**
```bash
flutter run -d windows  # or macos, linux
```

## Dependencies

Key packages used in this project:

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_staggered_grid_view` | ^0.7.0 | Staggered grid layout for notes |
| `image_picker` | ^1.0.0 | Pick images from device |
| `path_provider` | ^2.1.0 | Access app-specific directories |
| `shared_preferences` | ^2.2.2 | Persistent local storage |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
├── screens/                  # UI screens
├── widgets/                  # Reusable widgets
├── services/                 # Business logic
└── utils/                    # Utility functions

android/                       # Android native code
ios/                          # iOS native code
web/                          # Web platform files
macos/                        # macOS platform files
windows/                      # Windows platform files
linux/                        # Linux platform files
```

## How to Use

1. **Open the App** - Launch the Note App on your device or emulator
2. **Create a Note** - Tap the '+' button to create a new note
3. **Add Content** - Type your note content and optionally add images
4. **Save Note** - Tap save to store your note locally
5. **View Notes** - Browse all notes in the staggered grid view
6. **Edit Note** - Tap on any note to edit it
7. **Delete Note** - Long press or use the delete option to remove a note

## Build for Production

### Android
```bash
flutter build apk
# or for split APKs
flutter build apk --split-per-abi
# or for App Bundle
flutter build appbundle
```

### iOS
```bash
flutter build ios
```

### Web
```bash
flutter build web
```

### macOS/Windows/Linux
```bash
flutter build macos    # or windows, linux
```

## Troubleshooting

**No devices found:**
```bash
flutter devices
```

**Build cache issues:**
```bash
flutter clean
flutter pub get
flutter run
```

**Plugin errors:**
```bash
flutter pub get
flutter pub upgrade
```

**Android emulator issues:**
- Ensure Android SDK is properly installed
- Check `android/local.properties` points to your Android SDK

## Development

### Code Quality
```bash
flutter analyze     # Run dart analyzer
flutter test        # Run unit tests
```

### Formatting Code
```bash
dart format .       # Format all files
```

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Submit feature requests
- Create pull requests with improvements

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Flutter Community](https://flutter.dev/community)

---

**Happy Note Taking! 📝**

# Linux Notes — TechNotes-inspired UI update

- Rebuilt Home as a responsive documentation dashboard with a sidebar/drawer, search, subject cards and progress statistics.
- Added an all-notes card grid, subject filters, bookmarks and command searches.
- Continued reading opens the last-read note.
- Enhanced the reading screen with a larger title, chapter context, and Previous/Next navigation.
- Preserved existing JSON learning content, quiz, personal notes, copy history and settings.
- Retained the earlier startup-error handling for SharedPreferences; native plugin persistence still requires on-device verification.

## Build on Windows

```powershell
flutter create --platforms=android --org com.example .
flutter clean
flutter pub get
flutter build apk --release
```

The source was not compiled or tested on an Android device in this environment.

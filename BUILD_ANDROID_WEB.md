# Windows build steps

Run inside the linux_notes folder:

```powershell
flutter create --platforms=android,web .
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build web --release --base-href "/linux_note/"
```

Do not run flutter create after making custom Android/Web platform changes without reviewing the changes.

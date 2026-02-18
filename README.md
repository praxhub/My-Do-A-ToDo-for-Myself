# My-Do (Version 1.1)

My-Do is an offline Flutter productivity app for personal planning, task tracking, and day planning.
It supports local-first task management with image and voice attachments, calendar visibility, and a responsive Android widget.
Version 1.1 focuses on widget reliability, performance, journal improvements, and dark-theme polish.

## Why I Built This

I built **My-Do** for myself because I wanted a focused app that matches my daily workflow instead of forcing cloud-first complexity.
I needed one private place to capture tasks fast, attach context (images/voice), and check progress without internet dependency.
This project is my personal productivity tool first, so each release prioritizes practical features I use every day.

## Version

- Current version: `1.1.1+4`
- Release tag target: `v1.1`

## Core Features (v1.1)

- Offline task CRUD (create, edit, delete, complete)
- Due date and priority (Low / Medium / High)
- Image attachment (camera/gallery, local storage)
- Voice note recording and playback (local storage)
- Day Plan (priority-first day planning with optional date)
- Calendar task view by date
- Light/Dark mode toggle with animation
- Android home widgets:
  - ToDo widget
  - Day Plan widget
  - Checkbox toggle actions
  - Scrollable task list (not fixed to 5 items)
  - Quick add (`+`) and Open action
  - Dark/Light theme sync
- Theme-based splash launch (light/dark logo)

## Tech Stack

- Flutter (stable)
- Local storage: Hive
- Home widget bridge: `home_widget`
- No backend, no login, no cloud sync

## Repository

`https://github.com/praxhub/My-Do-A-ToDo-for-Myself.git`

## Changelog

See `CHANGELOG.md` for release notes.

---

## 1. Clone Project

### Windows (PowerShell)

```powershell
git clone https://github.com/praxhub/My-Do-A-ToDo-for-Myself.git
cd "My-Do-A-ToDo-for-Myself"
```

### macOS / Linux

```bash
git clone https://github.com/praxhub/My-Do-A-ToDo-for-Myself.git
cd My-Do-A-ToDo-for-Myself
```

---

## 2. Pull Latest Changes

### Windows (PowerShell)

```powershell
cd "path\to\My-Do-A-ToDo-for-Myself"
git pull origin main
```

### macOS / Linux

```bash
cd /path/to/My-Do-A-ToDo-for-Myself
git pull origin main
```

---

## 3. Prerequisites

- Flutter SDK (stable channel)
- Git
- Android SDK + platform-tools
- Android device (USB debugging enabled) or emulator

Check setup:

```bash
flutter doctor -v
```

---

## 4. Install Dependencies

From project root:

```bash
flutter pub get
```

---

## 5. Run the App

### Android device

```bash
flutter devices
flutter run -d <device_id>
```

### Emulator

```bash
flutter emulators
flutter emulators --launch <emulator_id>
flutter run
```

---

## 6. Build APK

### Release APK

```bash
flutter build apk --release
```

Output:

`build/app/outputs/flutter-apk/app-release.apk`

### Debug APK

```bash
flutter build apk --debug
```

Output:

`build/app/outputs/flutter-apk/app-debug.apk`

---

## 7. Screenshots (Manual Add)

Add screenshots in:

`docs/screenshots/`

Recommended files:

- `home.png`
- `add_edit_task.png`
- `calendar.png`
- `day_plan.png`
- `widget_light.png`
- `widget_dark.png`
- `splash_light.png`
- `splash_dark.png`

---

## 8. Project Structure

- `lib/screens/` UI screens
- `lib/models/` data models
- `lib/data/` database + repositories
- `lib/services/` media and widget sync services
- `android/` Android native config and widget files

---

## Notes

- App is fully offline.
- Data is stored only on device.
- Internet/auth/cloud features are intentionally out of scope.

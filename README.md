# My-Do (Version 1.0)

My-Do is an offline productivity app built with Flutter to manage tasks, daily notes, and lightweight planning in one place.
It is designed for fast personal use with local-first storage, clean UI flows, and support for image and voice attachments.
Version 1.0 focuses on reliability and privacy by keeping everything on-device with no login, cloud sync, or backend dependency.

## Why I Built This

I built **My-Do** for myself because I wanted a simple app that matched how I actually plan my day. Most apps I tried were either too complicated or forced internet/cloud-based workflows that I did not need.

I wanted one private, offline space where I could quickly add tasks, attach images or voice notes when needed, and keep one daily note without distractions.

So this project started as my personal productivity tool first, and Version 1.0 is intentionally focused on practical features that I use every day.

## Version

- Current version: `1.0`

## Core Features (v1.0)

- Offline task CRUD (create, edit, delete, complete)
- Due date and priority (Low / Medium / High)
- Image attachment (camera/gallery, local storage)
- Voice note recording and playback (local storage)
- Daily Notes (one entry per date)
- Calendar task view by date
- Light/Dark mode toggle with animation
- Android home widget (today count + top tasks)

## Tech Stack

- Flutter (stable)
- Local storage: Hive
- No backend, no login, no cloud sync

## Repository

`https://github.com/praxhub/My-Do-A-ToDo-for-Myself.git`

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

## 2. Pull Latest Changes (Update Existing Copy)

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

Install these before running:

- Flutter SDK (stable channel)
- Dart SDK (comes with Flutter)
- Git
- Android SDK + platform tools
- A connected Android device (USB debugging) or Android emulator

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

### Option A: Run on connected Android device

```bash
flutter devices
flutter run -d <device_id>
```

### Option B: Run on emulator

```bash
flutter emulators
flutter emulators --launch <emulator_id>
flutter run
```

### Option C: Run on desktop/web (if needed)

```bash
flutter run -d windows
flutter run -d chrome
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

## 7. Project Structure (High Level)

- `lib/screens/` UI screens
- `lib/models/` data models
- `lib/data/` database + repositories
- `lib/services/` media and widget sync services
- `android/` Android native config and widget files

---

## Notes

- App is fully offline in v1.0.
- Data is stored only on device.
- Internet/auth/cloud features are intentionally out of scope for this version.

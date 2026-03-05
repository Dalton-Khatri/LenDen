# LenDen - लेनदेन

A mobile app to track money between friends. Log who gave what, see live balances, settle dues, and export PDF reports too.

---

## Features

- Add friends with a photo or emoji avatar
- Log transactions with reason, note, and date
- Live balance per friend (green = they owe you, red = you owe them)
- Settle one transaction or all at once (long press)
- Star important transactions and view them in the Analysis tab
- Export per-friend PDF or a full date-range report for all friends
- Edit friend name, photo, or avatar anytime
- Anonymous sign-in, no email or password needed
- Firebase cloud sync, data is safe across sessions

---

## Download

[![Download APK](https://img.shields.io/badge/Download-APK-3DDC84?style=flat-square&logo=android)](https://github.com/YOUR_USERNAME/lenden/releases/latest/download/lenden.apk)

Android only. When installing, tap **Allow from this source** if prompted.

---

## Requirements

- Flutter 3.0+
- Android 5.0+ (minSdk 21)
- Firebase project with Firestore and Anonymous Auth enabled

---

## Running Locally

**1. Clone and install dependencies**
```bash
git clone https://github.com/Dalton-Khatri/lenden.git
cd lenden
flutter pub get
```

**2. Set up Firebase**
- Create a project at [console.firebase.google.com](https://console.firebase.google.com)
- Enable **Anonymous Authentication**
- Enable **Cloud Firestore** (test mode)
- Run `flutterfire configure` and select Android
- Replace `lib/firebase_options.dart` with the generated file

**3. Run the app**
```bash
flutter run
```

**4. Build release APK**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Tech Stack

- **Flutter** : UI framework
- **Firebase Firestore** : real-time cloud database
- **Firebase Auth** : anonymous authentication
- **pdf + share_plus** : PDF generation and sharing
- **image_picker** : camera and gallery for friend photos

---

## How It Works

**I Gave** : you paid for someone. They owe you. Balance goes green.

**I Took** : someone paid for you. You owe them. Balance goes red.

Settle a transaction to mark it cleared. Long press a friend on the home screen to settle everything at once. The Analysis screen shows your full picture — total to receive, total to pay, and net position.

---
## Contributing

Contributions are encouraged. If you’re planning significant changes, please open an issue first so we can discuss your proposal before you proceed.



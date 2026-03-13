# Filament Stock Tracker (FITED)

macOS desktop app to track 3D printing filament spool inventory with shared cloud state (Firebase) and audit log.

## Features
- Materials: PP, TPU, PLA, ABS, PETG
- Add / reduce stock with reason (Print, Stock In, etc.)
- Real-time sync across team members via Firestore
- Audit log with user email, timestamp, and reason
- Low stock threshold alert
- Company login restricted to @fited.co accounts

## Requirements
- Xcode 15+
- macOS 13+
- Firebase project (Firestore + Auth)

## Setup
1. Clone the repo
2. Open `FilamentStockTracker.xcodeproj`
3. Add `GoogleService-Info.plist` to the project (not committed — get it from your Firebase Console or team lead)
4. In **Signing & Capabilities**, select your own Apple ID as Team
5. Build & Run (Cmd + R)

## Team
Developed by Özge Sevin Keskin — FITED Teknoloji A.Ş.

# PulsePair

Companion app for a Bluetooth heart-rate sensor (simulated), built for the "Walk in Our Customer Shoes" workshop. SwiftUI, iOS 17+, no third-party dependencies.

Screens: clinician sign-in, Pair sensor, Live reading, Sessions, Patient profile, and Chaos (Crash, Handled error, Slow call, Server error, Freeze, Heavy list, Memory hog, Ask AI).

## Run

```sh
./run.sh              # Test build (Debug), yellow banner
./run.sh Production   # Production build (Release), red banner
VERSION=1.1.0 BUILD=2 ./run.sh
```

The script builds, installs and launches on the iPhone 17 simulator without a debugger attached, so crashes get reported. It prints the dSYM path at the end. Set `SIMULATOR="iPhone 17 Pro"` to use another device.

The build setting `PULSEPAIR_ENV` (Test in Debug, Production in Release) is exposed as `AppEnvironment.current`.

## Ask AI

```sh
cp AIConfig.example.plist PulsePair/AIConfig.plist
```

Paste the team's API key into `PulsePair/AIConfig.plist`. The file is git-ignored.

## Luciq

```sh
cp LuciqConfig.example.plist PulsePair/LuciqConfig.plist
```

Paste the app tokens into `PulsePair/LuciqConfig.plist`: `testToken` for Test builds and `productionToken` for Production builds. The file is git-ignored.

Production builds only report crashes and APM. Session Replay, bug reporting, repro steps, user steps and network logs are off, and users are identified by ID only.

# PerformanceTracker

iOS + Apple Watch performance assessment app for Matt Gates / Ridge Cell Repair LLC.

> Source-of-truth docs live in the parent directory: `../CLAUDE.md`, `../docs/`.

## Phase 1 — MVP Build

Phase 1 grades **Physical Health** (HealthKit), **Revenue** (manual), and **Client Work** (manual). Phase 2 categories show as `—` (incomplete) until Gmail/GitHub integrations land.

## Build & deploy

> **iOS Simulator is unusable on this iMac** (OCLP+Haswell kernel-panics on sim boot).
> Tests run on macOS host. App deploys directly to iPhone 17 Pro Max + Watch Ultra 3.

### Setup (one-time)

```bash
# Sync repo to iMac (kokonoe → iMac via tar+ssh, since rsync isn't on Windows)
cd /j/fitness/PerformanceTracker
tar cf - --exclude='.DS_Store' . | ssh imac 'cd ~/Developer/PerformanceTracker && tar xf -'

# xcodegen is bootstrapped from source on the iMac (no brew needed):
ssh imac 'cd ~/Developer && git clone --depth 1 https://github.com/yonaskolb/XcodeGen.git \
  && cd XcodeGen && swift build -c release --jobs 1'
# binary lives at: ~/Developer/XcodeGen/.build/release/xcodegen
```

### Generate Xcode project (after any project.yml change)

```bash
ssh imac 'cd ~/Developer/PerformanceTracker && ~/Developer/XcodeGen/.build/release/xcodegen generate'
```

### Run host tests (no sim)

```bash
ssh imac 'cd ~/Developer/PerformanceTracker && xcodebuild \
  -project PerformanceTracker.xcodeproj \
  -scheme PerformanceTrackerHost \
  -destination "platform=macOS" \
  -jobs 1 \
  CODE_SIGNING_ALLOWED=NO \
  test'
```

Pure-CPU work, no sim, no Metal stress. Should be the safest operation on the iMac.

### Deploy to iPhone 17 Pro Max

```bash
ssh imac 'cd ~/Developer/PerformanceTracker && xcodebuild \
  -project PerformanceTracker.xcodeproj \
  -scheme PerformanceTracker \
  -sdk iphoneos \
  -configuration Debug \
  -destination "id=AED90991-6134-50E6-B973-450072EAEB35" \
  -allowProvisioningUpdates \
  -jobs 1 \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=PVDSP4G3L4 \
  CODE_SIGN_IDENTITY="Apple Development" \
  ONLY_ACTIVE_ARCH=YES \
  build'
```

Device id `AED90991-6134-50E6-B973-450072EAEB35` = Matt's iPhone 17 Pro Max (`17pmax`).
The companion Watch app auto-installs to Apple Watch Ultra 3 via WatchConnectivity pairing.

### First-time provisioning (must be done in Xcode GUI)

Free Apple ID provisioning profiles can ONLY be issued from the Xcode UI on first attempt:
1. VNC/Screen Share into iMac
2. Open `PerformanceTracker.xcodeproj`
3. Click the project → PerformanceTracker target → Signing → "Try Again" if needed
4. Repeat for PerformanceTrackerWatch target
5. Once profiles are issued, all future builds work from CLI

## HealthKit & free Apple ID — known risk

HealthKit is historically a **restricted entitlement** that may require a paid Apple Developer Program ($99/year). Team `PVDSP4G3L4` is a **Personal Team (free)**. When building:

1. Xcode will try to provision a free profile with HealthKit.
2. If Apple rejects, the error will mention "HealthKit capability requires paid program."
3. Fallback: remove `com.apple.developer.healthkit` from the entitlements, rebuild. Matt enters all health data manually until he enrolls.

Test this with a simulator build first — simulator entitlements are laxer.

## Critical iMac rules (from wiki)

- **LOCK screen (Ctrl+Cmd+Q), do NOT log out** — logout kills keychain + Xcode session
- **Always build with `-jobs 1`** — OCLP+Haswell thermal crash under parallel compile
- **Prefer CLI over GUI** — indexing + compile simultaneously crashes the machine
- Free Apple ID provisioning profiles can ONLY be generated via Xcode GUI first time — expect one-time GUI step

## File structure

```
PerformanceTracker/
├── project.yml                   # xcodegen config (source of truth)
├── PerformanceTracker/           # iOS app sources
│   ├── App/                      # entry + ContentView
│   ├── Models/                   # SwiftData: Assessment, HealthMetrics, ManualEntry
│   ├── ViewModels/               # @Observable VMs
│   ├── Views/                    # SwiftUI screens
│   ├── Services/                 # HealthKitService, AssessmentEngine, GradingRubric
│   ├── Persistence/              # DataController, SeedData
│   ├── Utilities/                # Logger, DateExtensions
│   └── Resources/                # Info.plist, entitlements
├── PerformanceTrackerWatch/      # watchOS app sources
├── Shared/                       # Grade, Category, WatchMessage
└── Tests/                        # XCTest — GradingRubricTests, AssessmentEngineTests
```

## Version

0.1.0 (Phase 1 MVP) — April 2026

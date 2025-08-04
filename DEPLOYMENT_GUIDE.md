# CareGiver iOS App - Deployment Guide

## Quick Setup Instructions

### 1. Prerequisites
- macOS with Xcode 15.0 or later installed
- iOS Simulator (comes with Xcode)
- Minimum iOS target: 17.0

### 2. Opening the Project
1. Navigate to the project folder: `/Users/shashivelur/Projects/CareGiver`
2. Double-click `CareGiver.xcodeproj` to open in Xcode
3. Wait for Xcode to index the project files

### 3. Building and Running
1. **Select Target**: In Xcode, select "CareGiver" scheme and choose an iOS Simulator (iPhone 15 recommended)
2. **Build**: Press `Cmd + B` to build the project
3. **Run**: Press `Cmd + R` to run on simulator

### 4. Expected App Flow
1. **Launch Screen**: Shows CareGiver logo with heart icon
2. **Login Screen**: Simple username entry with Login/Register buttons
3. **Registration Flow**: Complete caregiver registration with optional patient addition
4. **Main App**: 5-tab navigation with hamburger menu

## Troubleshooting Common Issues

### Build Errors
If you encounter build errors, check:

1. **Deployment Target**: Ensure iOS deployment target is set to 17.0
   - Select project in navigator → Build Settings → iOS Deployment Target

2. **Bundle Identifier**: Verify bundle identifier is unique
   - Project Settings → General → Bundle Identifier

3. **Simulator Selection**: Make sure you've selected an iOS simulator, not a device

### Runtime Issues

1. **Storyboard Issues**: If views don't load properly:
   - Clean build folder: `Product → Clean Build Folder`
   - Rebuild: `Cmd + B`

2. **Core Data Issues**: If data persistence fails:
   - Reset simulator: `Device → Erase All Content and Settings`
   - Rebuild and run again

### Verification Steps

#### Test the Complete Flow:
1. **Launch App** → Should show login screen
2. **Tap "Register New Caregiver"** → Registration form appears
3. **Fill form and register** → Success message appears
4. **Return to login** → Enter username and login
5. **Main app loads** → 5 tabs visible at bottom
6. **Tap hamburger menu** → Left slide menu appears
7. **Navigate tabs** → Each tab loads appropriate view

#### Expected Features Working:
- ✅ Tab bar navigation (Home, Calendar, Chatbot, Tracking, Social)
- ✅ Hamburger menu with slide animation
- ✅ User registration and login
- ✅ Patient management in Home tab
- ✅ Core Data persistence
- ✅ Menu item navigation (Profile, Settings, etc.)

## Project Structure Verification

The project should have this structure:
```
CareGiver/
├── CareGiver.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/CareGiver.xcscheme
└── CareGiver/
    ├── AppDelegate.swift
    ├── SceneDelegate.swift
    ├── Info.plist
    ├── ViewControllers/ (14 Swift files)
    ├── Models/ (6 files including Core Data)
    └── Resources/
        ├── Assets.xcassets/
        └── Base.lproj/
            ├── Main.storyboard
            └── LaunchScreen.storyboard
```

## Key Configuration Files

### Info.plist
- ✅ Scene-based lifecycle configured
- ✅ Main storyboard set to "Main"
- ✅ Launch screen set to "LaunchScreen"

### Main.storyboard
- ✅ Login and Register scenes configured
- ✅ Tab bar controller with 5 tabs
- ✅ Navigation controllers for each tab
- ✅ Menu view controllers for hamburger menu

### Core Data Model
- ✅ Caregiver entity with required attributes
- ✅ Patient entity with relationship to Caregiver
- ✅ 1:many relationship properly configured

## Performance Tips
- App should launch in < 3 seconds on simulator
- UI transitions should be smooth (0.3s animations)
- Core Data operations are optimized for small datasets

## Support
If you encounter issues:
1. Check Xcode console for error messages
2. Verify all files are present in project navigator
3. Clean and rebuild if needed
4. Reset simulator if Core Data issues persist

## Success Indicators
- ✅ App builds without errors
- ✅ Launches on iOS Simulator
- ✅ All navigation works smoothly
- ✅ Data persists between app launches
- ✅ UI is responsive and professional looking

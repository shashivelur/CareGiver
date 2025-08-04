# CareGiver iOS App

A comprehensive iOS application designed for caregivers to manage and monitor multiple patients with ease.

## Features

### 🏠 Main Navigation
- **Tab Bar Navigation**: 5 main sections (Home, Calendar, Chatbot, Tracking, Social Groups)
- **Hamburger Menu**: Quick access to Profile, Settings, Notifications, Reports, and Help
- **Default Tab**: Home screen for easy access to primary features

### 👤 User Authentication & Registration
- **Login Screen**: Simple username-based authentication
- **Registration**: Complete caregiver registration with personal details
- **Patient Management**: Add multiple patients during registration

### 📱 Core Functionality
1. **Home Tab**: Dashboard with patient overview and quick actions
2. **Calendar Tab**: Schedule appointments and track medication times
3. **Chatbot Tab**: AI assistant for health-related queries
4. **Tracking Tab**: Monitor vital signs and health trends
5. **Social Groups Tab**: Connect with other caregivers

### 🔧 Menu Features
- **Profile**: View caregiver information and patient count
- **Settings**: App preferences and account management
- **Notifications**: System alerts and reminders
- **Reports**: Health analytics and summaries
- **Help & Support**: Documentation and customer support

## Technical Architecture

### 📊 Data Management
- **Core Data**: SQLite-based data persistence
- **Easy Management**: Simple API for developers with minimal SQL experience
- **Relationship**: 1:many between caregivers and patients

### 🏗️ Code Structure
```
CareGiver/
├── AppDelegate.swift              // App lifecycle management
├── SceneDelegate.swift            // Scene management
├── ViewControllers/               // All view controllers
│   ├── LoginViewController.swift
│   ├── RegisterViewController.swift
│   ├── MainTabBarController.swift
│   ├── HomeViewController.swift
│   ├── CalendarViewController.swift
│   ├── ChatbotViewController.swift
│   ├── TrackingViewController.swift
│   ├── SocialGroupsViewController.swift
│   ├── MenuViewController.swift
│   ├── ProfileViewController.swift
│   ├── SettingsViewController.swift
│   ├── NotificationsViewController.swift
│   ├── ReportsViewController.swift
│   └── HelpViewController.swift
├── Models/                        // Core Data models
│   ├── CareGiver.xcdatamodeld
│   ├── CoreDataManager.swift
│   ├── Caregiver+CoreDataClass.swift
│   ├── Caregiver+CoreDataProperties.swift
│   ├── Patient+CoreDataClass.swift
│   └── Patient+CoreDataProperties.swift
├── Resources/                     // UI resources
│   ├── Main.storyboard
│   ├── LaunchScreen.storyboard
│   └── Assets.xcassets
└── Info.plist                    // App configuration
```

### 📱 UI/UX Design
- **Storyboard-Based**: Complete UI built using Interface Builder
- **No-Code UI**: Developers can modify UI without writing code
- **Clean Design**: Simple, intuitive interface similar to popular apps like X.com
- **Responsive**: Adapts to different screen sizes

## Core Data Model

### Caregiver Entity
- `username`: String (unique identifier)
- `firstName`: String
- `lastName`: String
- `email`: String
- `phoneNumber`: String
- `dateOfBirth`: Date
- `createdAt`: Date
- `patients`: Relationship (one-to-many)

### Patient Entity
- `firstName`: String
- `lastName`: String
- `dateOfBirth`: Date
- `email`: String? (optional)
- `phoneNumber`: String? (optional)
- `createdAt`: Date
- `caregiver`: Relationship (many-to-one)

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.0

### Installation
1. Clone the repository
2. Open `CareGiver.xcodeproj` in Xcode
3. Select your target device or simulator
4. Press `Cmd + R` to build and run

### First Time Setup
1. Launch the app
2. Tap "Register New Caregiver"
3. Fill in your information
4. Add patients (optional)
5. Complete registration
6. Login with your username

## Usage

### For Caregivers
1. **Register**: Create your caregiver account
2. **Add Patients**: Register patients under your care
3. **Navigate**: Use tab bar for main features
4. **Access Menu**: Tap hamburger menu for additional options
5. **Manage**: Track patient information and health data

### For Developers
1. **UI Customization**: Use Interface Builder to modify layouts
2. **Data Management**: Use `CoreDataManager.shared` for all database operations
3. **Add Features**: Extend existing view controllers or create new ones
4. **Navigation**: Follow the established tab bar + hamburger menu pattern

## Development Guidelines

### Adding New Features
1. Create view controller in appropriate folder
2. Add storyboard scene if needed
3. Wire up navigation in `MainTabBarController`
4. Follow existing code patterns

### Database Operations
```swift
// Create caregiver
let caregiver = CoreDataManager.shared.createCaregiver(
    username: "johndoe",
    firstName: "John",
    lastName: "Doe",
    email: "john@example.com",
    phoneNumber: "123-456-7890",
    dateOfBirth: Date()
)

// Add patient
let patient = CoreDataManager.shared.createPatient(
    firstName: "Jane",
    lastName: "Smith",
    dateOfBirth: Date(),
    email: "jane@example.com",
    phoneNumber: "098-765-4321",
    caregiver: caregiver
)

// Fetch patients
let patients = CoreDataManager.shared.fetchPatients(for: caregiver)
```

## Future Enhancements
- Real-time notifications
- Integration with health devices
- Telemedicine features
- Advanced reporting and analytics
- Multi-language support
- Cloud synchronization

## Support
For technical support or questions, contact the development team or refer to the Help & Support section within the app.

## License
This project is proprietary software. All rights reserved.

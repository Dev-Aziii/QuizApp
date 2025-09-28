# 📚 ITS Reviewer App

A Flutter-based quiz and reviewer application designed to help users study interactively.  
The app supports **user authentication**, **role-based access (Admin/User)**, **quiz management**, and **quiz history tracking**.

---

## 🚀 Features
- 🔑 User authentication (Email/Password & Google Sign-In)  
- 👥 Role-based access (Admin dashboard & User dashboard)  
- 📝 Quiz management (create, update, delete quizzes — for Admins)  
- 🎯 Take quizzes with progress tracking  
- 📊 Quiz history stored in Firestore for review  
- 🌙 Clean and responsive UI  

---

## 🛠️ Tech Stack
- **Flutter** (Dart)  
- **Firebase Authentication** (Email/Password & Google)  
- **Cloud Firestore** (User data, quizzes, and history)  
- **Firebase Hosting/Functions** (if used)  

---

## 📂 Project Structure
itsreviewer_app/
│-- android/ # Android-specific files
│-- ios/ # iOS-specific files
│-- lib/ # Main Flutter app source code
│ │-- view/ # UI screens
│ │-- widgets/ # Reusable widgets
│ │-- services/ # Firebase/Auth services
│ │-- models/ # Data models
│-- assets/ # Images, icons, etc.
│-- test/ # Unit and widget tests
│-- pubspec.yaml # Flutter dependencies
│-- firebase.json # Firebase project config (safe to share)
│-- firestore.rules # Firestore security rules
│-- firestore.indexes.json# Firestore indexes

yaml
Copy code

---

## ⚙️ Setup Instructions
1. **Clone the repo**
   ```bash
   git clone https://github.com/your-username/itsreviewer_app.git
   cd itsreviewer_app
Install dependencies

bash
Copy code
flutter pub get
Configure Firebase

Add your google-services.json in /android/app/.

Add your GoogleService-Info.plist in /ios/Runner/.

(Optional) Update firebase.json, firestore.rules, and firestore.indexes.json if needed.

Run the app

bash
Copy code
flutter run

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

---

## 🖼️ App UI Previews
👤 User Interface
<p align="center"> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/557755926_1294240341954216_2582961351322791769_n.jpg?updatedAt=1760090936829" width="160" alt="Login Page"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/553934097_1348019436932911_4046907876408934922_n.jpg?updatedAt=1760090936711" width="160" alt="Register Page"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/552679723_786262654301547_2988112328059190782_n.jpg?updatedAt=1760090936837" width="160" alt="User Dashboard"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/552223649_2125675334625318_1538003905889414485_n.jpg?updatedAt=1760090936761" width="160" alt="Quiz Selection"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/552693568_1489127815744093_6045072750873096989_n.jpg?updatedAt=1760090936733" width="160" alt="Quiz Play"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/554195450_1551070076311619_2140282409086343922_n.jpg?updatedAt=1760090936703" width="160" alt="Quiz Result"/> </p>
🧑‍💼 Admin Interface
<p align="center"> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/557777071_829558586423432_1744642277586282765_n.jpg?updatedAt=1760090936855" width="160" alt="Admin Dashboard"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/552928315_819142143835999_7965029135459801725_n.jpg?updatedAt=1760090936829" width="160" alt="Sidebar"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/552693568_1440111567097775_5029514559196089960_n.jpg?updatedAt=1760090936820" width="160" alt="Manage Quiz"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/554828500_1816812622542858_8722796989700993644_n.jpg?updatedAt=1760090936777" width="160" alt="Add Quiz Questions"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/553200351_1351606746490377_242663727165332682_n.jpg?updatedAt=1760090936883" width="160" alt="Manage Category"/> <img src="https://ik.imagekit.io/q22xsdezi5/app%20ui/553599669_24732135486449436_5028069426248290060_n.jpg?updatedAt=1760090936756" width="160" alt="Add Category"/> </p>

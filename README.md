🧠 DermaScannAI_V2
DermaScannAI_V2 is an AI-assisted skin lesion tracking and risk analysis application. It helps users monitor their skin health by capturing images of moles or lesions, analyzing them for potential risks using AI, and maintaining a visual history to detect changes over time.
---
🌟 Key Features
🔍 1. AI Analysis Engine
📸 Camera Integration  
High-quality photo capture optimized for skin imaging.
🤖 AI Diagnosis  
Real-time analysis to detect skin conditions and provide risk assessments.
📊 Confidence Levels  
Transparent reporting with confidence percentages for every scan.
---
🗂️ 2. Image & History Management
☁️ Cloud Storage  
Secure backup of scan photos using Cloudinary or AWS.
📅 Visual Timeline  
Chronological history to track changes in size, shape, or color of lesions.
📡 Offline Mode  
Capture images and data offline; sync automatically when reconnected.
---
👤 3. Advanced User Profile
🩺 Medical History  
Store skin type, age, and existing conditions to improve AI accuracy.
🎨 Custom Avatars  
Personalized profiles with secure authentication.
---
🧑‍⚕️ 4. Professional & Safety Tools
📄 Doctor Export  
Generate professional PDF reports for dermatologists.
📍 Dermatologist Finder  
Locate nearby skin specialists using GPS.
⏰ Reminders  
Automated notifications for follow-up scans (e.g., every 2 weeks).
---
📋 Prerequisites
Ensure the following tools are installed:
Flutter SDK ^3.0.0 or higher
Node.js v16.x or higher
MongoDB (local instance or MongoDB Atlas)
Git
---
🛠️ Installation & Setup
🔧 1. Backend Setup (Node.js)
```bash
cd backend
npm install
```
🔐 Environment Configuration
Create a `.env` file inside the `backend/` directory:
```env
PORT=3000
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret

CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

EMAIL_USER=your_gmail@gmail.com
EMAIL_PASS=your_gmail_app_password
```
Start the server:
```bash
npm start
```
---
📱 2. Mobile App Setup (Flutter)
Install dependencies:
```bash
flutter pub get
```
Generate Hive adapters:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
Update your API base URL in service files to match your local IP address.
Run the app:
```bash
flutter run
```
---
🔑 Permissions
The app requires the following permissions:
📷 Camera – Capture lesion images
📍 Location – Find nearby dermatologists
💾 Storage – Save images locally
🔔 Notifications – Follow-up reminders
---
🏗️ Tech Stack
Frontend: Flutter (Dart)
State Management: Provider
Local Database: Hive
Backend: Node.js & Express
Database: MongoDB
Cloud Storage: Cloudinary
Authentication: JWT & Google Sign-In
---
⚠️ Disclaimer
> This application is an AI-assisted tracking tool and **does not replace professional medical advice**.  
> Always consult a certified dermatologist for any skin-related concerns.

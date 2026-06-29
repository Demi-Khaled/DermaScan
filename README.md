# 📋 DermaScan — Project Specifications

> **Version:** 1.0.0 | **Last Updated:** June 2026 | **Status:** Active Development

---

## 📖 Project Overview

**DermaScan** is an AI-powered mobile health application that enables users to scan and analyze skin lesions using their smartphone camera. The app leverages a custom-trained deep learning model (ResNet101) to classify skin conditions, assess risk levels, and provide personalized recommendations — helping users identify potentially dangerous lesions early and connect with dermatologists.

### Problem Statement
Skin cancer is one of the most common cancers worldwide. Early detection dramatically improves survival rates, yet access to dermatology specialists is often limited by cost, geography, and wait times. DermaScan bridges this gap by providing AI-assisted preliminary screening directly on the user's mobile device.

### Target Users
- General consumers concerned about skin health
- Patients tracking existing skin conditions over time
- Individuals in areas with limited dermatologist access

---

## ✨ Features

### 1. 🔬 AI Analysis Engine
- **Camera Integration** — High-quality in-app skin lesion photography
- **AI Diagnosis** — Deep learning classification via a custom ResNet101 model
- **7-Class Classification** — Melanoma, Nevus, BCC, Actinic Keratosis, Benign Keratosis, Dermatofibroma, Vascular
- **Risk Stratification** — Results mapped to High / Medium / Low risk levels
- **Confidence Scoring** — Probability output alongside the diagnosis
- **Plain-Language Explanations** — Human-readable descriptions for each condition

### 2. 🖼️ Image & Scan Management
- **Cloud Image Storage** — Lesion photos securely stored via Cloudinary
- **Scan History Timeline** — Visual history of all previous scans
- **Progress Tracking** — Side-by-side comparison to detect lesion changes over time

### 3. 👤 User Profile & Medical Context
- **Profile Pictures** — Custom user avatars
- **Medical History** — Skin type, age, and pre-existing condition logging
- **Account Settings** — Profile editing and preference management

### 4. 💎 Professional Polish
- **PDF Report Generation** — Export scan reports to share with dermatologists
- **Push Notifications** — Follow-up scan reminders (via `flutter_local_notifications`)
- **Offline Mode** — Photo capture while offline; synced when connectivity is restored (via Hive local storage)
- **In-App Chat** — AI-powered chat assistant for skin health Q&A
- **Share Results** — Share analysis results via native sharing

### 5. 🧭 Onboarding & Safety
- **Animated Onboarding** — 4-page walkthrough for new users
- **Dermatologist Finder** — Location-based nearby specialist discovery (via Geolocator)
- **Emergency Helplines** — Quick access to dermatology emergency contacts

### 6. 🔐 Authentication
- **Email / Password** — Secure registration and login with JWT
- **Google Sign-In** — OAuth 2.0 via Google
- **Secure Token Storage** — JWT stored via `flutter_secure_storage`

---

## 🏗️ System Architecture

DermaScan is a **three-tier distributed system**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│           (iOS / Android — Primary User Interface)          │
└───────────────────────┬─────────────────────────────────────┘
                        │ HTTPS / JSON
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Node.js / Express.js Backend API               │
│   ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│   │   Auth      │  │   Lesion     │  │   Analysis       │  │
│   │  (JWT/OAuth)│  │   CRUD       │  │   Orchestrator   │  │
│   └─────────────┘  └──────────────┘  └──────────────────┘  │
└─────┬──────────────────────┬────────────────────┬───────────┘
      │                      │                    │
      ▼                      ▼                    ▼
┌──────────┐         ┌──────────────┐    ┌────────────────────┐
│ MongoDB  │         │  Cloudinary  │    │ Python/Flask       │
│  Atlas   │         │ (Image CDN)  │    │ AI Service         │
│(Database)│         └──────────────┘    │ (AWS ECS Fargate)  │
└──────────┘                             │ ResNet101 Model    │
                                         └────────────────────┘
```

### Data Flow for Skin Analysis
1. User captures image in Flutter app → sent to Node.js backend
2. Backend uploads image to **Cloudinary** → receives stable CDN URL
3. Backend fetches image bytes → POSTs to Python **AI Service** (`/predict`)
4. AI Service runs **ResNet101 inference** → returns JSON (class, confidence, risk)
5. Backend saves result to **MongoDB** → returns formatted response to app
6. Flutter app displays diagnosis, risk level, and recommendations

---

## 🛠️ Tech Stack

### 📱 Frontend — Flutter (Mobile)

| Category | Package | Version | Purpose |
|---|---|---|---|
| **Framework** | Flutter SDK | ≥3.0.0 | Cross-platform mobile framework |
| **State Management** | provider | ^6.1.1 | App-wide state management |
| **Networking** | http | ^1.2.0 | REST API communication |
| **Camera** | camera | ^0.10.5+9 | In-app camera capture |
| **Image Picker** | image_picker | ^1.2.1 | Gallery image selection |
| **Local Storage** | hive + hive_flutter | ^2.2.3 / ^1.1.0 | Offline-first local DB |
| **Secure Storage** | flutter_secure_storage | ^10.0.0 | Encrypted JWT storage |
| **Auth** | google_sign_in | ^7.2.0 | Google OAuth |
| **Notifications** | flutter_local_notifications | ^21.0.0 | Push reminders |
| **Timezone** | timezone + flutter_timezone | ^0.11.0 / ^5.1.0 | Notification scheduling |
| **PDF** | pdf + printing | ^3.12.0 / ^5.14.3 | Report generation |
| **Location** | geolocator | ^14.0.2 | Dermatologist finder |
| **Connectivity** | connectivity_plus | ^7.1.1 | Offline detection |
| **Sharing** | share_plus | ^13.1.0 | Native share sheet |
| **Image Display** | cached_network_image | ^3.4.1 | Optimized image loading |
| **Markdown** | flutter_markdown | ^0.7.7+1 | AI chat rendering |
| **Loading** | flutter_spinkit | ^5.2.2 | Loading animations |
| **Internationalisation** | intl | ^0.19.0 | Date/number formatting |
| **URL Launcher** | url_launcher | ^6.3.2 | External links |
| **App Info** | package_info_plus | ^10.1.0 | Version metadata |

**Dev Dependencies:**
- `hive_generator` + `build_runner` — Hive adapter code generation
- `flutter_launcher_icons` — Custom app icon pipeline
- `flutter_lints` — Static analysis

---

### ⚙️ Backend — Node.js / Express.js

| Category | Package | Version | Purpose |
|---|---|---|---|
| **Runtime** | Node.js | Latest LTS | JavaScript server runtime |
| **Framework** | express | ^5.2.1 | REST API framework |
| **Database ORM** | mongoose | ^9.3.1 | MongoDB object modeling |
| **Database Driver** | mongodb | ^7.2.0 | Native MongoDB driver |
| **Authentication** | jsonwebtoken | ^9.0.3 | JWT signing & verification |
| **Password Hashing** | bcrypt | ^6.0.0 | Secure password storage |
| **Google Auth** | google-auth-library | ^10.6.2 | Google ID token verification |
| **File Uploads** | multer | ^2.1.1 | Multipart form handling |
| **Cloud Storage** | cloudinary | ^1.41.3 | Image CDN upload |
| **Multer Storage** | multer-storage-cloudinary | ^4.0.0 | Direct Cloudinary stream upload |
| **Email** | nodemailer | ^8.0.6 | Transactional email (SMTP) |
| **HTTP Client** | axios | ^1.16.1 | AI service communication |
| **CORS** | cors | ^2.8.6 | Cross-origin resource sharing |
| **Environment** | dotenv | ^17.3.1 | Environment variable loading |
| **Form Data** | form-data | ^4.0.5 | Multipart forwarding to AI |

**API Route Groups:**

| Route | Description |
|---|---|
| `POST /api/auth/register` | User registration |
| `POST /api/auth/login` | Email/password login |
| `POST /api/auth/google` | Google OAuth token exchange |
| `GET /api/lesions` | List user's lesion history |
| `POST /api/lesions` | Create new lesion record |
| `DELETE /api/lesions/:id` | Remove a lesion record |
| `POST /api/analyze` | Trigger AI analysis on an uploaded image |
| `POST /api/chat` | AI chat assistant endpoint |
| `GET /health` | Health check |

---

### 🧠 AI Service — Python / Flask

| Category | Library | Purpose |
|---|---|---|
| **Web Framework** | Flask | Lightweight REST microservice |
| **WSGI Server** | Gunicorn | Production-grade HTTP server |
| **Deep Learning** | PyTorch (torch) | Model inference engine |
| **Model Arch** | torchvision (ResNet101) | Pre-trained CNN backbone |
| **Augmentation** | albumentations | Image preprocessing pipeline |
| **Image Processing** | Pillow (PIL) | Image I/O and format conversion |
| **Numerical** | NumPy | Tensor/array operations |
| **Deployment** | Docker + AWS ECS Fargate | Containerized serverless deployment |

**Model Details:**
- **Architecture:** ResNet101 with custom classification head
  - `Linear(2048 → 512) → BatchNorm → ReLU → Dropout(0.4)`
  - `Linear(512 → 256) → BatchNorm → ReLU → Dropout(0.3)`
  - `Linear(256 → 7)`
- **Input:** RGB image resized to 224×224, normalized with ImageNet stats
- **Output:** 7-class softmax probabilities
- **Inference Mode:** CPU-only (no GPU required on ECS Fargate)
- **Model File:** `best_resnet101_model.pth` (~167 MB)

**Classification Output:**

| Class | Risk Level | Description |
|---|---|---|
| Melanoma | High | Serious skin cancer |
| BCC | High | Basal Cell Carcinoma |
| Actinic Keratosis | Medium | Precancerous growth |
| Nevus | Low | Common mole |
| Benign Keratosis | Low | Non-cancerous growth |
| Dermatofibroma | Low | Harmless skin growth |
| Vascular | Low | Benign vascular lesion |

---

### 💾 Data Storage

| Service | Purpose | Provider |
|---|---|---|
| **MongoDB Atlas** | Primary database (users, lesions, scan history) | MongoDB Cloud |
| **Cloudinary** | Image CDN and permanent lesion photo storage | Cloudinary |
| **Hive** | On-device local storage for offline support | Local (device) |

**MongoDB Data Models:**

```
User
├── name: String
├── email: String (unique)
├── password: String (bcrypt hashed)
├── googleId: String (optional)
├── profilePicture: String (URL)
├── skinType: String
├── age: Number
└── createdAt: Date

Lesion
├── userId: ObjectId → User
├── imageUrl: String (Cloudinary URL)
├── analysisResult:
│   ├── class_name: String
│   ├── risk_level: "high" | "medium" | "low"
│   ├── confidence: Number (0–1)
│   ├── explanation: String
│   └── recommendation: String
├── bodyLocation: String
└── createdAt: Date
```

---

### ☁️ Infrastructure & Deployment

| Layer | Service | Details |
|---|---|---|
| **AI Microservice** | AWS ECS Fargate | Docker container, auto-scaled, serverless |
| **Container Registry** | AWS ECR | Private Docker image repository |
| **Database** | MongoDB Atlas | Managed cloud database, M0/M10+ cluster |
| **Image Storage** | Cloudinary | Free/paid tier CDN image hosting |
| **Email** | SMTP (Gmail) | Transactional email via Nodemailer |
| **Backend Hosting** | Any Node.js host | e.g., Railway, Render, EC2 |

---

## ⚙️ Environment Requirements

### Backend `.env` file (`backend/.env`):
```env
PORT=3000
MONGO_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/dermascan
JWT_SECRET=your_jwt_secret_key
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
EMAIL_USER=your_gmail@gmail.com
EMAIL_PASS=your_gmail_app_password
AI_SERVICE_URL=http://<ai-service-host>:5000
```

### Flutter — API Base URL
Update the base URL constant in `lib/core/constants.dart` to point to your deployed backend.

### AI Service — Docker
The AI service is containerized via `ai-service/Dockerfile`. Build and push to AWS ECR, then deploy on ECS Fargate. See `ecr_ecs_setup_guide.md` for step-by-step instructions.

---

## 📐 Non-Functional Requirements

| Requirement | Target |
|---|---|
| **Availability** | 99.5% uptime for backend and AI service |
| **AI Response Time** | < 5 seconds per skin analysis (CPU inference) |
| **Concurrency** | UUID-based temp files prevent race conditions on multi-request ECS tasks |
| **Security** | HTTPS only; JWT expiry enforced; passwords bcrypt-hashed |
| **Data Privacy** | No raw images retained on server; stored only on Cloudinary with user-scoped URLs |
| **Offline Support** | Core app navigation and history viewable offline via Hive cache |
| **Platforms** | Android (primary), iOS (supported) |
| **Flutter SDK** | Dart SDK >=3.0.0 <4.0.0 |
| **Node.js** | Latest LTS (v18+) |
| **Python** | 3.9+ (for PyTorch compatibility) |

---

## 📁 Project Structure

```
DermaScan/
├── lib/                        # Flutter application source
│   ├── main.dart               # App entry point
│   ├── core/                   # Constants, shared utilities
│   ├── models/                 # Dart data models
│   ├── screens/                # UI screens
│   │   ├── auth/               # Login, register
│   │   ├── home/               # Home dashboard
│   │   ├── camera/             # Camera capture
│   │   ├── analysis/           # AI result display
│   │   ├── lesion/             # Lesion history
│   │   ├── profile/            # User profile
│   │   ├── dermatologist/      # Finder & helplines
│   │   ├── share/              # Export & share
│   │   └── onboarding/         # Onboarding flow
│   ├── services/               # API & local service layer
│   ├── widgets/                # Reusable UI components
│   ├── theme/                  # Color palette & typography
│   └── routing/                # App navigation/routing
│
├── backend/                    # Node.js API
│   ├── index.js                # Server entry point
│   ├── db.js                   # MongoDB connection
│   ├── models/                 # Mongoose schemas (User, Lesion)
│   ├── controllers/            # Route handler logic
│   ├── routes/                 # Express route definitions
│   ├── middleware/             # Auth & validation middleware
│   ├── config/                 # Configuration helpers
│   └── .env                    # Environment variables (not committed)
│
├── ai-service/                 # Python AI microservice
│   ├── app.py                  # Flask application & endpoints
│   ├── predictor.py            # Model loading & inference logic
│   ├── best_resnet101_model.pth# Trained model weights (~167 MB)
│   ├── requirements.txt        # Python dependencies
│   ├── Dockerfile              # Container definition
│   └── gunicorn.conf.py        # Gunicorn server config
│
├── assets/                     # App assets (images, icons)
├── pubspec.yaml                # Flutter dependency manifest
├── architecture.md             # System architecture diagram
├── aws_deployment_guide.md     # AWS setup instructions
├── ecr_ecs_setup_guide.md      # ECR/ECS deployment guide
└── PROJECT_SPECS.md            # This document
```

---

## 🚀 Quick Start

### 1. Backend
```bash
cd backend
npm install
# Configure your .env file
npm start
```

### 2. AI Service (Local)
```bash
cd ai-service
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
python app.py
```

### 3. Flutter App
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 📎 Related Documents

- [architecture.md](./architecture.md) — Mermaid system architecture diagram
- [aws_deployment_guide.md](./aws_deployment_guide.md) — Full AWS deployment walkthrough
- [ecr_ecs_setup_guide.md](./ecr_ecs_setup_guide.md) — Docker + ECR + ECS Fargate setup

---

> DermaScan is intended as a screening aid only and does not replace professional medical diagnosis.

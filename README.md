# DermaScan

DermaScan is an advanced skin analysis application designed to help users assess their skin health and recommend skincare solutions based on AI-driven analysis and user input.

## Features
- **User-Friendly Interface:** Intuitive design for easy navigation.
- **Skin Analysis:** Utilize advanced algorithms to analyze skin conditions.
- **Personalized Recommendations:** Tailored skincare solutions based on individual needs.
- **Progress Tracking:** Document changes over time to visualize improvement.

## Installation
To install DermaScan, follow these steps:
1. **Clone the repository:**  
   ```bash
   git clone https://github.com/Demi-Khaled/DermaScan.git
   ```  
2. **Navigate to the directory:**  
   ```bash
   cd DermaScan
   ```  
3. **Install dependencies:**  
   ```bash
   npm install
   ```

## 📦 Dependencies

### 🔧 Backend (Node.js)
Install all required packages:
```bash
npm install
```
Main dependencies used:
- express
- mongoose
- dotenv
- jsonwebtoken
- cloudinary
- multer
- cors
- nodemailer

### 📱 Frontend (Flutter)
Install Flutter packages:
```bash
flutter pub get
```
Main dependencies (from pubspec.yaml):
- provider
- http
- image_picker
- hive
- hive_flutter
- path_provider
- flutter_local_notifications
- geolocator

## ⚙️ Useful Commands

### 🖥️ Backend
Run server:
```bash
npm start
```
Run with auto-reload (optional):
```bash
npm run dev
```

### 📱 Flutter
Run the app:
```bash
flutter run
```
Build APK:
```bash
flutter build apk
```
Clean project:
```bash
flutter clean
```
Generate Hive adapters:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📁 Environment Variables
Create `.env` inside `backend/`:
```
PORT=3000
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
EMAIL_USER=your_gmail@gmail.com
EMAIL_PASS=your_gmail_app_password
```

⚠️ **Important Note:** Don't just copy dependencies blindly — make sure they match:
- your `package.json`
- your `pubspec.yaml`

If you want help, send those files and we'll verify compatibility!

## Usage
After installation, you can start the application with:
```bash
npm start
```

## Contributing
We welcome contributions from the community! If you'd like to contribute, please follow these steps:
1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes and commit them (`git commit -m 'Add new feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Open a pull request.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact
For any inquiries, please contact us at support@dermascan.com.

---

**Last Updated:** 2026-04-27
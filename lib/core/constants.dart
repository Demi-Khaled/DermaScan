class AppConstants {
  // Replace with your physical phone's local network IP if testing on a real device
  // e.g., 'http://44.214.2.215:3000/api'
  // 10.0.2.8 is the localhost equivalent for Android Emulator
  static const String apiBaseUrl = 'http://44.214.2.215:3000/api';

  // Guidelines for users taking photos of skin lesions
  static const String skinLesionGuidelines = '''
+  # Beginner’s Guide to Capturing Clear Skin Lesion Photos
+  
+  ## 1️⃣ Lighting
+  - Use natural daylight whenever possible; avoid harsh overhead lights or direct sunlight that can cause shadows.
+  - Ensure the area is evenly lit; you may diffuse light with a thin white sheet if needed.
+  
+  ## 2️⃣ Background
+  - Place the lesion on a plain, light‑colored surface (e.g., white or light‑gray paper) that contrasts with the skin tone.
+  - Remove clutter, clothes, or accessories from the frame.
+  
+  ## 3️⃣ Stability
+  - Hold the phone with both hands or use a tripod/stand to keep the camera steady.
+  - Rest your elbows on a stable surface if you don’t have a tripod.
+  
+  ## 4️⃣ Angle & Distance
+  - Position the camera perpendicular (90°) to the skin; avoid tilting.
+  - Keep the camera at a distance that fills the lesion in the frame but still shows surrounding skin (about 2‑3 inches away).
+  
+  ## 5️⃣ Scale Reference
+  - Place a ruler, a coin, or a standard size marker next to the lesion for size reference.
+  
+  ## 6️⃣ Focus & Resolution
+  - Tap the screen on the lesion to lock focus and exposure.
+  - Use the highest resolution available; disable digital zoom (move closer instead).
+  
+  ## 7️⃣ Avoid Shadows & Reflections
+  - Ensure no shadows fall on the lesion; adjust lighting or reposition.
+  - If the skin is shiny, gently dry it before photographing.
+  
+  ## 8️⃣ Skin Preparation
+  - Clean the area gently; avoid makeup, lotions, or oils.
+  - Pat the skin dry if it’s wet.
+  
+  ## 9️⃣ Review Before Submitting
+  - Verify the lesion is entirely within the frame and in focus.
+  - Ensure the scale marker is clearly visible.
+  - Take a few extra shots to choose the best one.
+  ''';
}

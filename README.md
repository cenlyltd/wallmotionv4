# WallMotion Flutter App

Live Wallpaper Premium untuk Android — Flutter + Firebase + Midtrans QRIS

---

## 🚀 Setup Step-by-Step

### 1. Firebase Project
1. Buka [console.firebase.google.com](https://console.firebase.google.com)
2. **Create Project** → nama: `wallmotion`
3. Aktifkan services:
   - **Authentication** → Email/Password
   - **Firestore Database** → Start in production mode
   - **Storage** → Start in production mode
   - **Functions** → Upgrade ke **Blaze plan** (wajib untuk Cloud Functions + Midtrans)

### 2. Flutter Firebase Config
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login Firebase
firebase login

# Generate firebase_options.dart
flutterfire configure --project=YOUR_PROJECT_ID
```
Ini akan generate file `lib/firebase_options.dart` otomatis.

### 3. Cloud Functions Setup
```bash
cd functions
npm install

# Set environment variables
firebase functions:secrets:set MIDTRANS_SERVER_KEY
# Masukkan: SB-Mid-server-xxxx (sandbox) atau Mid-server-xxxx (production)

firebase functions:secrets:set MIDTRANS_ENV
# Masukkan: sandbox atau production

# Deploy functions
firebase deploy --only functions
```

**Set Notification URL di Midtrans Dashboard:**
```
https://asia-southeast1-YOUR_PROJECT_ID.cloudfunctions.net/midtransWebhook
```

### 4. Deploy Firestore Rules & Storage Rules
```bash
firebase deploy --only firestore:rules,storage:rules
```

### 5. Android Keystore (untuk release build)
```bash
keytool -genkey -v -keystore wallmotion.jks \
  -alias wallmotion -keyalg RSA -keysize 2048 -validity 10000
```
Simpan file `wallmotion.jks` dan buat `android/key.properties`:
```
storeFile=../../wallmotion.jks
storePassword=YOUR_STORE_PASS
keyAlias=wallmotion
keyPassword=YOUR_KEY_PASS
```

### 6. Codemagic Setup
1. Push project ke GitHub/GitLab
2. Buka [codemagic.io](https://codemagic.io) → Add app → pilih repo
3. Pilih workflow: **Flutter App** → pakai `codemagic.yaml`
4. Set environment variables di Codemagic:
   - `FIREBASE_GOOGLE_SERVICES` → base64 dari `google-services.json`
     ```bash
     base64 android/app/google-services.json
     ```
   - `MIDTRANS_ENV` → `sandbox` atau `production`
   - `NOTIFY_EMAIL` → email notifikasi build
5. Upload keystore ke **Code Signing** → Android

### 7. Tambah Produk (Admin)
Buka Firebase Console → Firestore → koleksi `products` → tambah dokumen:
```json
{
  "name": "Nama Wallpaper",
  "description": "Deskripsi",
  "price": 15000,
  "originalPrice": 25000,
  "tags": ["Aesthetic", "Dark"],
  "previewUrl": "https://storage.googleapis.com/...",
  "hdStoragePath": "videos/nama_file.mp4",
  "color": "neon",
  "featured": true,
  "active": true,
  "createdAt": "timestamp"
}
```

**Upload video ke Firebase Storage:**
- Preview (watermarked): `previews/nama.mp4`
- HD original: `videos/nama.mp4`

---

## 📁 Struktur Project
```
wallmotion/
├── lib/
│   ├── main.dart
│   ├── router.dart
│   ├── firebase_options.dart     ← generate via flutterfire configure
│   ├── models/models.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── product_service.dart
│   │   └── order_service.dart
│   ├── screens/
│   │   ├── screens.dart          ← onboarding, home
│   │   ├── detail/detail_screen.dart
│   │   ├── payment/payment_screen.dart
│   │   ├── access/access_screen.dart
│   │   └── profile/profile_screen.dart
│   └── widgets/widgets.dart
├── functions/                    ← Cloud Functions (Node.js)
│   ├── src/index.ts
│   └── package.json
├── android/
├── pubspec.yaml
├── codemagic.yaml
├── firebase.json
├── firestore.rules
└── storage.rules
```

---

## 🔑 Environment Variables (Codemagic)

| Key | Value |
|-----|-------|
| `FIREBASE_GOOGLE_SERVICES` | base64 dari google-services.json |
| `MIDTRANS_ENV` | `sandbox` atau `production` |
| `NOTIFY_EMAIL` | email kamu |

---

## 💡 Flow Aplikasi

```
User buka app → Onboarding → Register/Login
    ↓
Home (grid wallpaper streaming dari Firebase Storage preview)
    ↓
Tap wallpaper → Detail screen (fullscreen preview + info)
    ↓
Tap "Beli" → Cloud Function createOrder dipanggil
    ↓
Midtrans buat QRIS → tampil di Payment screen
    ↓
User scan QRIS → Midtrans webhook → Firestore update status='paid'
    ↓
App real-time detect paid → Auto navigate ke Access screen
    ↓
Tap "Pasang Wallpaper" → Cloud Function generate signed URL
    ↓
App stream video ke temp → Set wallpaper → hapus temp file
    ↓
Done! Live wallpaper aktif tanpa file tersimpan di gallery 🎉
```

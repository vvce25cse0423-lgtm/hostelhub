# 🏠 HostelHub — Smart Hostel Management System

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.22-blue?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green?logo=supabase)
![License](https://img.shields.io/badge/license-MIT-purple)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-orange?logo=github-actions)
![Free Tier](https://img.shields.io/badge/hosting-free%20tier-success)

**A production-ready, fully cloud-based hostel management system for colleges and universities.**

[Features](#-features) • [Tech Stack](#-tech-stack) • [Setup Guide](#️-setup-guide) • [CI/CD](#-cicd) • [Screenshots](#-screenshots)

</div>

---

## 📱 Features

### 👤 Authentication
- Email & Password login via **Supabase Auth**
- Role-based access: **Student** and **Admin/Warden**
- Secure JWT token management
- Auto-redirect based on role after login

### 🏠 Room Management
- View all rooms with occupancy, type, and rent info
- Grid display with status indicators (Available / Full / Maintenance)
- Filter by status, type, and floor
- Admin: update room status, assign students to rooms

### 📋 Complaint System
- Raise complaints with **8 categories** (Maintenance, Food, Security, etc.)
- Upload complaint images to **Supabase Storage**
- Real-time status tracking: **Pending → In Progress → Resolved**
- Admin response/notes visible to student
- Status timeline visualization

### ✅ Attendance System
- One-tap **Check-In / Check-Out**
- Today's status card with live status
- Full attendance history with duration calculation
- Date-filtered logs

### 💳 Fees Management
- View all fee records (Hostel, Mess, Security Deposit, etc.)
- Payment status: **Paid / Pending / Overdue**
- Summary dashboard with total due
- Mock payment flow (ready for **Razorpay** integration)
- Transaction ID tracking

### 🔔 Notifications
- Real-time notifications via **Supabase Realtime**
- Auto-notification on complaint status change
- Mark as read / Mark all as read
- Categorized by type with icons

### 👨‍💼 Admin Dashboard
- Overview stats: Room counts, complaint distribution
- **Pie chart** for complaint status breakdown
- Room management: update status, view occupancy
- Student management: view all students, assign rooms

### 🎨 UI/UX
- **Material 3** design system
- **Dark mode** support with toggle
- Smooth animations (flutter_animate)
- Loading shimmer effects
- Empty state illustrations
- Responsive layouts

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x + Dart |
| **State Management** | Riverpod + riverpod_annotation |
| **Navigation** | GoRouter (declarative, role-aware) |
| **Backend** | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| **HTTP Client** | Supabase Flutter SDK (built-in) |
| **Local Storage** | flutter_secure_storage |
| **Charts** | fl_chart |
| **Images** | image_picker + cached_network_image |
| **CI/CD** | GitHub Actions |
| **Architecture** | Clean Architecture (data → domain → presentation) |

---

## 🗄️ Database Schema

```
users           → id, name, email, role, usn, phone, profile_image_url
rooms           → id, room_number, floor, type, capacity, occupancy, status, monthly_rent
allocations     → id, student_id (→ users), room_id (→ rooms), allocated_at, is_active
complaints      → id, student_id, title, description, category, status, image_url, admin_note
attendance      → id, student_id, check_in, check_out, notes
fees            → id, student_id, amount, status, fee_type, month, due_date, paid_at
notifications   → id, user_id, title, body, type, is_read, data
```

All tables have:
- ✅ Foreign key constraints
- ✅ Check constraints (valid enum values, capacity limits)
- ✅ Performance indexes
- ✅ Row Level Security (RLS) policies
- ✅ Auto-updated timestamps (triggers)
- ✅ Cascade deletes

---

## ⚙️ Setup Guide

### Step 1: Prerequisites

```bash
# Install Flutter (https://flutter.dev/docs/get-started/install)
flutter --version   # Should be 3.x

# Install Git
git --version

# Install VS Code with Flutter extension (recommended)
```

### Step 2: Clone and Install Dependencies

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/hostelhub.git
cd hostelhub

# Get Flutter packages
flutter pub get
```

### Step 3: Create Supabase Project

1. Go to **[supabase.com](https://supabase.com)** → Sign up (free)
2. Click **"New Project"**
3. Fill in:
   - Project name: `hostelhub`
   - Database password: (save this!)
   - Region: Choose closest to India (e.g., Singapore)
4. Wait ~2 minutes for project to initialize

### Step 4: Run Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **"New Query"**
3. Copy the entire contents of `supabase/schema.sql`
4. Paste and click **"Run"**
5. You should see: `Success. No rows returned`

### Step 5: Create Storage Buckets

The schema.sql already creates the buckets, but verify:
1. Go to **Storage** in Supabase dashboard
2. You should see: `complaint-images` and `profile-images`
3. Both should be set to **Public**

If not visible, run in SQL Editor:
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('complaint-images', 'complaint-images', TRUE),
       ('profile-images', 'profile-images', TRUE)
ON CONFLICT DO NOTHING;
```

### Step 6: Get Supabase Credentials

1. Go to **Settings → API** in Supabase dashboard
2. Copy:
   - **Project URL**: `https://xxxxxxxxxxxx.supabase.co`
   - **anon/public key**: `eyJhbGci...` (long JWT token)

### Step 7: Configure Environment Variables

**Option A: Compile-time variables (Recommended for CI/CD)**

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
```

**Option B: Direct configuration (Development only)**

Open `lib/core/constants/app_constants.dart` and update:
```dart
static const String supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

> ⚠️ Never commit real credentials to git! Use Option A for production.

### Step 8: Create Demo Users

**Create Student Account:**
1. Go to Supabase → Authentication → Users → **Add User**
2. Email: `student@demo.com`, Password: `demo1234`
3. After creation, go to SQL Editor and run:
```sql
UPDATE public.users
SET name = 'Demo Student', usn = '1XX21CS000'
WHERE email = 'student@demo.com';
```

**Create Admin Account:**
1. Add User: Email: `admin@demo.com`, Password: `admin1234`
2. Run:
```sql
UPDATE public.users
SET name = 'Admin User', role = 'admin'
WHERE email = 'admin@demo.com';
```

**Add Sample Fees for Student:**
```sql
INSERT INTO public.fees (student_id, amount, fee_type, month, due_date, status)
SELECT
    id,
    5000, 'hostel', '2024-01', '2024-01-10', 'paid'
FROM public.users WHERE email = 'student@demo.com';

INSERT INTO public.fees (student_id, amount, fee_type, month, due_date, status)
SELECT
    id,
    2500, 'mess', '2024-01', '2024-01-15', 'pending'
FROM public.users WHERE email = 'student@demo.com';
```

### Step 9: Run the App

```bash
# Run on connected Android device or emulator
flutter run --dart-define=SUPABASE_URL=YOUR_URL \
            --dart-define=SUPABASE_ANON_KEY=YOUR_KEY

# Build debug APK
flutter build apk --debug \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_KEY

# The APK will be at:
# build/app/outputs/flutter-apk/app-debug.apk
```

---

## 🔁 CI/CD

### GitHub Actions Setup

The project includes an automated APK build pipeline.

#### Step 1: Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit: HostelHub"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/hostelhub.git
git push -u origin main
```

#### Step 2: Add GitHub Secrets

1. Go to your GitHub repo → **Settings → Secrets and Variables → Actions**
2. Click **"New repository secret"**
3. Add these two secrets:

| Secret Name | Value |
|-------------|-------|
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | `eyJhbGci...` |

#### Step 3: Trigger Build

The workflow triggers automatically on:
- Every push to `main` or `master`
- Every pull request to `main`
- Manual trigger (Actions → Run workflow)

#### Step 4: Download APK

1. Go to **GitHub Actions** tab in your repo
2. Click the latest workflow run
3. Scroll down to **Artifacts**
4. Download `hostelhub-debug-apk-{run_number}`

---

## 📲 APK Installation

1. Download `app-debug.apk` from GitHub Actions artifacts
2. Transfer to Android phone
3. Enable **"Install from unknown sources"** in Android settings
4. Open the APK file and install
5. Launch HostelHub!

---

## 🔐 Security

- **JWT Authentication**: Supabase handles token lifecycle
- **Row Level Security**: Database enforces access control even if app is compromised
- **Role-Based Access**: Admin-only routes are protected at both app and database level
- **Input Validation**: All forms validate before API calls
- **Secure Storage**: Tokens stored in flutter_secure_storage (encrypted)
- **No Secrets in Code**: All credentials via compile-time dart-define or GitHub Secrets

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/     # App-wide constants, Supabase config
│   ├── errors/        # Failure types, exceptions
│   ├── router/        # GoRouter navigation setup
│   ├── theme/         # Material 3 light/dark themes
│   └── utils/         # Helper functions
├── data/
│   ├── datasources/   # Supabase client, remote sources
│   ├── models/        # Data models (UserModel, RoomModel, etc.)
│   └── repositories/  # Repository implementations
├── domain/
│   ├── entities/      # Business entities
│   ├── repositories/  # Repository interfaces
│   └── usecases/      # Business logic use cases
└── presentation/
    ├── providers/     # Riverpod state notifiers
    ├── screens/
    │   ├── auth/      # Login, Register
    │   ├── student/   # Dashboard, Profile
    │   ├── admin/     # Admin Dashboard, Rooms, Students
    │   ├── complaints/# List, Detail, Create
    │   ├── attendance/# Attendance tracking
    │   ├── fees/      # Fee management
    │   └── rooms/     # Room list and detail
    └── widgets/       # Reusable UI components
```

---

## 🌐 Deployment

This app uses **100% free tier services**:

| Service | Provider | Free Tier |
|---------|----------|-----------|
| Database | Supabase PostgreSQL | 500MB |
| Auth | Supabase Auth | 50,000 users |
| Storage | Supabase Storage | 1GB |
| Realtime | Supabase Realtime | 200 concurrent |
| CI/CD | GitHub Actions | 2,000 min/month |
| APK Hosting | GitHub Artifacts | 500MB/month |

No credit card required! ✅

---

## 🔮 Future Enhancements

- [ ] Razorpay payment gateway integration
- [ ] FCM push notifications
- [ ] Biometric authentication
- [ ] QR code for attendance
- [ ] PDF fee receipt generation
- [ ] Admin bulk fee creation
- [ ] Visitor management
- [ ] iOS support

---

## 🤝 Contributing

1. Fork the project
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">
Built with ❤️ using Flutter & Supabase | Free to use for students
</div>

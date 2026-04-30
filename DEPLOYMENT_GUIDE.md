# 🚀 HostelHub — Complete Deployment Guide

## Step 1: Initial Setup (5 min)

```bash
# 1. Clone / download the project
cd hostelhub

# 2. Install dependencies
flutter pub get

# 3. Generate code (IMPORTANT — run this after pub get)
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Step 2: Supabase Setup (10 min)

### 2a. Create Project
1. Visit [supabase.com](https://supabase.com) → Sign up free
2. Click **"New Project"** → name it `hostelhub`
3. Set a strong DB password (save it!)
4. Choose region: **ap-southeast-1** (Singapore — best for India)
5. Wait ~2 min for project to spin up

### 2b. Run Database Schema
1. Supabase Dashboard → **SQL Editor** → New Query
2. Paste contents of `supabase/schema.sql`
3. Click **Run** ▶️

### 2c. Verify Storage Buckets
Dashboard → **Storage**:
- ✅ `complaint-images` (public)
- ✅ `profile-images` (public)

### 2d. Get Credentials
Dashboard → **Settings → API**:
```
Project URL:   https://xxxxxxxxxxxxxx.supabase.co
Anon Key:      eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Step 3: Configure the App (2 min)

**For development** — open `lib/core/constants/app_constants.dart`:
```dart
static const String supabaseUrl = 'https://YOUR_REF.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

**For production** — use dart-define (keeps secrets out of code):
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

---

## Step 4: Create Demo Users (5 min)

### In Supabase Dashboard → Authentication → Users → Add User:

**Student:**
- Email: `student@demo.com`
- Password: `demo1234`

After creating, run in SQL Editor:
```sql
UPDATE public.users
SET name = 'Rahul Kumar', usn = '1XX21CS001'
WHERE email = 'student@demo.com';

-- Add sample fees
INSERT INTO public.fees (student_id, amount, fee_type, month, due_date, status)
SELECT id, 5000, 'hostel', '2024-01', NOW() - INTERVAL '15 days', 'paid'
FROM public.users WHERE email = 'student@demo.com';

INSERT INTO public.fees (student_id, amount, fee_type, month, due_date, status)
SELECT id, 2500, 'mess', '2024-02', NOW() + INTERVAL '5 days', 'pending'
FROM public.users WHERE email = 'student@demo.com';

INSERT INTO public.fees (student_id, amount, fee_type, month, due_date, status)
SELECT id, 5000, 'hostel', '2023-12', NOW() - INTERVAL '30 days', 'overdue'
FROM public.users WHERE email = 'student@demo.com';
```

**Admin:**
- Email: `admin@demo.com`
- Password: `admin1234`

After creating, run in SQL Editor:
```sql
UPDATE public.users
SET name = 'Admin Singh', role = 'admin'
WHERE email = 'admin@demo.com';
```

---

## Step 5: Run Locally (2 min)

```bash
# List connected devices
flutter devices

# Run on device/emulator
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_KEY

# Run in debug mode (hot reload enabled)
flutter run --debug
```

---

## Step 6: Build APK (3 min)

```bash
# Debug APK (for testing — no signing needed)
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_KEY

# APK location:
# build/app/outputs/flutter-apk/app-debug.apk

# Release APK (for distribution)
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_KEY
```

---

## Step 7: Push to GitHub + CI/CD (5 min)

```bash
# Initialize git (if not already done)
git init
git add .
git commit -m "🚀 Initial: HostelHub production setup"

# Create repo on github.com then:
git remote add origin https://github.com/YOUR_USERNAME/hostelhub.git
git branch -M main
git push -u origin main
```

### Add GitHub Secrets:
1. GitHub Repo → **Settings → Secrets → Actions → New Secret**
2. Add:
   - `SUPABASE_URL` = `https://YOUR_REF.supabase.co`
   - `SUPABASE_ANON_KEY` = `eyJhbGci...`

### Trigger Build:
- Push any commit to `main` — GitHub Actions builds APK automatically
- Go to **Actions tab** → Download artifact from latest run

---

## Step 8: Deploy Edge Functions (Optional)

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy notification function
supabase functions deploy send-notification

# Deploy bulk fees function
supabase functions deploy create-bulk-fees
```

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Login with `student@demo.com` / `demo1234` works
- [ ] Student dashboard shows name and USN
- [ ] Rooms list loads with grid view
- [ ] Creating a complaint works (with and without image)
- [ ] Attendance check-in/check-out works
- [ ] Fees screen shows pending/paid amounts
- [ ] Login with `admin@demo.com` / `admin1234` works  
- [ ] Admin dashboard shows room and complaint stats
- [ ] Admin can assign room to student
- [ ] Dark mode toggle works
- [ ] Sign out and sign back in works

---

## 🐛 Troubleshooting

### "Failed to load rooms" error
→ Check RLS policies: run `SELECT * FROM public.rooms;` in SQL Editor
→ Ensure anon key is correct in app_constants.dart

### "No authenticated user" after login
→ Check Supabase Auth → Email confirmations (disable for testing)
→ Dashboard → Auth → Settings → Disable "Email Confirmations"

### Images not uploading
→ Check Storage bucket is set to **Public**
→ Check storage policies in SQL Editor:
```sql
SELECT * FROM storage.policies;
```

### Build runner errors
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Gradle build errors
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --debug
```

---

## 📞 Support

For issues:
1. Check Supabase logs: Dashboard → **Logs → API**
2. Check Flutter debug output: `flutter run --verbose`
3. Check RLS policies are correct for each table

---

*Built for students, by students. Free forever on Supabase free tier.* 🎓

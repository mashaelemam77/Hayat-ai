# Supabase connection

1. Create a project in Supabase.
2. Open SQL Editor, paste and run the contents of `supabase_schema.sql`.
3. Go to Project Settings > API and copy:
   - Project URL
   - anon public key
4. Run the app with your Supabase values:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SMART_REPORT_WEB_URL=http://10.0.2.2:8501
```

For a real phone, replace `SMART_REPORT_WEB_URL` with the deployed website URL or with your computer IP address, for example `http://192.168.1.20:8501`.

The Flutter app and the website should both use the same Supabase table: `public.reports`.

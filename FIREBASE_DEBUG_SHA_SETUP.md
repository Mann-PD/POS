# Fix Firebase DEVELOPER_ERROR and Firestore "database does not exist"

Your app fails because the **debug signing certificate** is not registered in Firebase. Add the SHA-1 (and SHA-256) of your debug keystore to the Firebase Android app.

## Step 1: Get your debug SHA-1 and SHA-256 (Windows)

**In PowerShell** (use `$env:USERPROFILE` so the path expands):

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**In Command Prompt (CMD)** use:

```cmd
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

If the debug keystore doesn't exist yet, run your Flutter app once in debug (`flutter run`), then run the command again.

From the output, copy:
- **SHA1:** (e.g. `AA:BB:CC:...`)
- **SHA-256:** (e.g. `AA:BB:CC:...`)

## Step 2: Add fingerprints in Firebase Console

**Your debug fingerprints** (copy these exactly):

| Type     | Value |
|----------|--------|
| SHA-1    | `9D:FD:92:EA:1C:C1:E4:02:28:C8:D8:FC:EF:79:03:F2:4F:EC:16:EE` |
| SHA-256  | `21:94:72:92:F2:16:8B:F3:2F:AD:94:62:A5:E5:25:65:12:44:72:39:C0:BF:AC:3B:93:B4:E4:0E:E7:61:7B:8B` |

1. Open [Firebase Console](https://console.firebase.google.com/) → select project **POS-SYSTEM** (`pos-system-9d8ac`).
2. Click the **gear icon** → **Project settings**.
3. Under **Your apps**, find the **Android** app with package **`com.example.pos_system`** (not `com.pos.system`).
4. Click **Add fingerprint** → paste the **SHA-1** above → Save.
5. Click **Add fingerprint** again → paste the **SHA-256** above → Save.

No need to re-download `google-services.json` for this; the same file works.

## Step 3: Rebuild and run

```bash
flutter clean
flutter run
```

After adding the fingerprints, **DEVELOPER_ERROR** should go away and Firestore should connect.

---

## What your latest run showed

- **Firebase Auth is working:** Login with `test@gmail.com` succeeded (id token and auth state listeners fired).
- **Firestore still fails:** After login, the app reads the user role from Firestore; that request fails with NOT_FOUND and DEVELOPER_ERROR.
- **Fix:** Add the SHA-1 and SHA-256 above to the **`com.example.pos_system`** Android app in Firebase (Step 2). Until that is done, Firestore and some GMS checks will keep failing.

---

## Still seeing DEVELOPER_ERROR or Firestore NOT_FOUND?

- **Right app?** Add fingerprints to the Android app with package **`com.example.pos_system`** only (not `com.pos.system`). In Project settings, confirm both SHA-1 and SHA-256 are listed under that app.
- **Google Cloud Console:** In [Google Cloud Console](https://console.cloud.google.com/) → project **pos-system-9d8ac** → **APIs & services** → **Credentials**, check the Android client for `com.example.pos_system` has the same SHA-1. If you only added in Firebase, wait a few minutes for sync.
- **Uninstall and reinstall:** Uninstall the app from the device (KB2001), then run `flutter run` again.
- **Wait 2–5 minutes** for new fingerprints to propagate, then try again.

If you use a different machine or CI, add that machine’s debug (or release) SHA-1/SHA-256 to the same Android app in Firebase.

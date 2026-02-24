# Auth & Android Log Troubleshooting

## 1. "Your account is inactive. Contact administrator."

**What it means:** Firebase Auth succeeded, but the user document in Firestore has `status` that is not `"Active"`.

**Automatic bootstrap:** If there is **no** user in the system with `status: "Active"`, the app calls the Cloud Function `bootstrapFirstUser`, which activates your account so you can log in. So if you're the only user and you're inactive, the next login should activate you and let you in.

- Deploy the function once: `firebase deploy --only functions` (from the project root). Then restart the app and try logging in again.

**Fix from the app (if you can log in as Super Admin):**

1. Log in with a **Super Admin** account.
2. Open **User Management** on the Super Admin dashboard.
3. Find the user and use the ⋮ menu → **Set Active**.

**Fix from Firebase Console (if no Super Admin can log in):**

1. Open [Firebase Console](https://console.firebase.google.com) → your project → **Firestore**.
2. Open the `users` collection and the document for the affected user (use the UID from Auth or search by email if you store it).
3. Set the `status` field to **`"Active"`** (string).

After updating, the user can sign in again.

---

## 2. GoogleApiManager DEVELOPER_ERROR

**Log lines:**
```
E/GoogleApiManager: Failed to get service from broker.
E/GoogleApiManager: java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'.
ConnectionResult{statusCode=DEVELOPER_ERROR, ...}
```

**What it means:** The Android app’s signing certificate (SHA-1 / SHA-256) is not registered in Firebase for this app.

**Fix:**

1. Get your debug SHA-1 and SHA-256. In a terminal, run:
   ```powershell
   cd android
   .\gradlew signingReport
   ```
   (On macOS/Linux: `./gradlew signingReport`)

2. In the output, find the **Variant: debug** section and copy the **SHA-1** and **SHA-256** values.

3. In **Firebase Console**:
   - Open your project → **Project settings** (gear) → **Your apps**.
   - Select your Android app (package name e.g. `com.example.pos_system`).
   - Under **SHA certificate fingerprints**, click **Add fingerprint** and add both **SHA-1** and **SHA-256**.
   - Save.

4. Rebuild and run the app. Allow a few minutes for Google’s servers to pick up the change.

For **release** builds, add the release keystore’s SHA-1 and SHA-256 from the same `signingReport` output (Variant: release).

---

## 3. Other log messages (usually safe to ignore)

- **FlagRegistrar / NativeCrypto / hiddenapi:** Internal Google Play Services; no action needed.
- **ApkAssets: Deleting an ApkAssets object:** System/other apps; not from your app.
- **ProviderInstaller / DynamiteModule:** Security provider loading; “Installed default security provider GmsCore_OpenSSL” is normal.

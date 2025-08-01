

---

# 📒 `UserProfileNotifier` vs `AdminUserProvider`

## 🔹 1. `UserProfileNotifier` – Global Auth + Routing Context

### Purpose:

`UserProfileNotifier` is the **global** user context provider that handles the **entire authentication lifecycle**, token resolution, and initial route access for the app. It operates *before dashboard mounting*.

### Where it's used:

* ✅ `main.dart`
* ✅ Routing (`onGenerateRoute`)
* ✅ `FranchiseGate` logic (franchise context & role checks)
* ✅ Login flow
* ❌ *Not used for dashboard screen internals (unless needed)*

### Responsibilities:

* Authenticate the current Firebase user.
* Resolve and store token claims (e.g., `roles`, `email`, `userId`).
* Determine which dashboard to send the user to (`/platform-owner`, `/admin`, etc.).
* Expose:

  ```dart
  user // AppUser (contains roles, email, UID)
  loading // boolean
  logout()
  refreshTokenClaims()
  ```

### Example:

```dart
final userNotifier = Provider.of<UserProfileNotifier>(context);
final user = userNotifier.user;
final loading = userNotifier.loading;
```

### Typical Structure of `.user`:

```json
{
  "uid": "abc123",
  "email": "admin@example.com",
  "roles": ["platform_owner", "developer"]
}
```

---

## 🔹 2. `AdminUserProvider` – Dashboard User + Franchise Context

### Purpose:

`AdminUserProvider` is injected **within** the dashboard layer (e.g., `/admin/dashboard`) and resolves a fully enriched `AdminUser` object including franchise-related metadata and Firestore-derived details.

### Where it's used:

* ✅ All dashboard screen files (analytics, orders, promos, etc.)
* ✅ All admin CRUD features and tools
* ❌ Not injected globally or at login/routing stage

### Responsibilities:

* Resolve Firestore-based `users/{userId}` document (with admin-level metadata).
* Load and expose detailed admin user fields.
* Tie the current user to the active `franchiseId` context.
* Support dashboard-specific access control (via `RoleGuard`).
* Expose:

  ```dart
  user // AdminUser (Firestorm doc)
  loading // boolean
  fetchAdminUser(userId)
  ```

### Example:

```dart
final adminUserProvider = Provider.of<AdminUserProvider>(context);
final user = adminUserProvider.user;
final loading = adminUserProvider.loading;
```

---

## 🔁 Why Split These?

| Reason                                   | Explanation                                                                                                                                                          |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ✅ **Global vs Local Scope**              | `UserProfileNotifier` handles auth-wide access and role token routing. `AdminUserProvider` fetches Firestore metadata post-login.                                    |
| ✅ **Firebase Auth vs Firestore Profile** | `UserProfileNotifier` uses Firebase token claims. `AdminUserProvider` maps these claims to Firestore documents (with `displayName`, timestamps, access flags, etc.). |
| ✅ **Dashboard Encapsulation**            | Prevents unnecessary global rebuilds from dashboard-only Firestore changes. Keeps auth lightweight and clean.                                                        |
| ✅ **Role Separation**                    | Supports routing decisions (`platform_owner` vs `hq_owner`) at login without relying on dashboard-specific profile resolution.                                       |

---

## 🧠 Developer Mental Model

* **Use `UserProfileNotifier`** for:

  * Determining which dashboard to load.
  * Checking roles for routing guards.
  * Accessing UID/email/token claims early.

* **Use `AdminUserProvider`** for:

  * Loading user-related Firestore data.
  * Granting access to dashboard modules.
  * Accessing `franchiseId`, last login, or internal permissions.

---

## 🔐 Security Considerations

* `UserProfileNotifier.user.roles` are derived from **Firebase token claims**, meaning they cannot be tampered with by the client (secure).
* `AdminUserProvider.user` is Firestore data and can include **additional metadata** (e.g., notes, internal tags) not meant for auth logic.

---

## 🔍 Example Usage Comparison

### ❌ Do not use this in dashboard:

```dart
final user = Provider.of<UserProfileNotifier>(context).user;
```

### ✅ Use this instead:

```dart
final adminUserProvider = Provider.of<AdminUserProvider>(context);
final user = adminUserProvider.user;
```

---

## 📁 File Placement

| Provider              | Path                                             |
| --------------------- | ------------------------------------------------ |
| `UserProfileNotifier` | `/lib/core/providers/user_profile_notifier.dart` |
| `AdminUserProvider`   | `/lib/core/providers/admin_user_provider.dart`   |

---
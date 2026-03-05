# BirthChain

A healthcare records management system that allows providers to register patients, scan QR codes, and maintain digital medical histories. Built with a .NET 9 backend and Flutter frontend.

## Architecture

```
CodeXtreme/
├── backend/          # .NET 9 Clean Architecture API
│   └── src/
│       ├── BirthChain.API/              # Controllers, Program.cs
│       ├── BirthChain.Application/      # DTOs, Interfaces, Services
│       ├── BirthChain.Domain/           # Entities (User, Provider, Client, Record, ActivityLog)
│       └── BirthChain.Infrastructure/   # EF Core, Repositories, Migrations
└── frontend/         # Flutter (Dart) mobile & desktop app
    └── lib/
        ├── app/          # Theme, routing, dashboard, profile, admin panel
        ├── core/         # API client, secure storage, constants, widgets
        ├── di/           # Dependency injection (get_it)
        └── features/     # auth, patients, records (data/domain/presentation)
```

## Prerequisites

| Tool | Version |
|------|---------|
| .NET SDK | 9.0+ |
| PostgreSQL | 14+ |
| Flutter SDK | 3.7+ |
| Android Studio | Latest (for emulator / Android builds) |

## Backend Setup

### 1. Configure the database

Install PostgreSQL and create a database. Then update the connection string in:

```
backend/src/BirthChain.API/appsettings.json
```

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=birthchain;Username=postgres;Password=YOUR_PASSWORD"
  },
  "Jwt": {
    "Key": "CHANGE_ME_SuperSecretKey_AtLeast32Chars!!",
    "Issuer": "BirthChain",
    "Audience": "BirthChainClient",
    "ExpireMinutes": 60
  }
}
```

> **Important:** Change the `Jwt:Key` to a secure random string (minimum 32 characters) before deploying.

### 2. Apply migrations

```bash
cd backend
dotnet ef database update \
  --project src/BirthChain.Infrastructure \
  --startup-project src/BirthChain.API
```

### 3. Run the API

```bash
cd backend
dotnet run --project src/BirthChain.API
```

The API will start on **http://localhost:5066**. Verify with:

```
GET http://localhost:5066/api/health
```

### Seed data

On first run the database is seeded with an admin account:

| Field | Value |
|-------|-------|
| Email | `nyaepeace@gmail.com` |
| Password | `UhoRaho@842` |
| Role | Admin |

## Frontend Setup

### 1. Install dependencies

```bash
cd frontend
flutter pub get
```

### 2. API base URL

The app auto-selects the API URL based on platform:

- **Android emulator** → `http://10.0.2.2:5066/api` (routes to host's localhost)
- **Windows / other** → `http://localhost:5066/api`

To change these, edit `frontend/lib/core/constants/app_constants.dart`.

### 3. Run on Windows

```bash
cd frontend
flutter run -d windows
```

### 4. Run on Android emulator

Start the emulator first, then:

```bash
# Launch emulator (example for Pixel_5 AVD)
emulator -avd Pixel_5 -gpu auto -no-snapshot-load

# Wait for it to boot, then deploy
cd frontend
flutter run -d emulator-5554
```

> **Tip:** If the emulator shows as "offline" in `adb devices`, restart ADB:
> ```bash
> adb kill-server && adb start-server
> ```

### 5. Build APK

```bash
cd frontend
flutter build apk --debug
```

Output: `frontend/build/app/outputs/flutter-apk/app-debug.apk`

## Roles & Workflow

| Role | Capabilities |
|------|-------------|
| **Admin** | Create provider accounts, manage patients, view activity logs |
| **Provider** | Scan QR codes, view patient data, register patients, add medical records |

1. Admin logs in and creates Provider accounts via **Profile → Manage Providers**
2. Provider logs in → sees **Patients** list, **Scan QR**, and **Profile** tabs
3. Provider registers a new patient → a QR code is generated
4. Provider scans a patient's QR code → views patient detail with medical history
5. Provider adds medical records (Diagnosis, Medication, Vaccination, Lab Result, Procedure)

## Tech Stack

- **Backend:** .NET 9, Entity Framework Core, PostgreSQL, JWT authentication
- **Frontend:** Flutter 3.7+, Provider state management, Dio HTTP client, get_it DI, qr_flutter
- **Design:** Material 3, navy blue (#1A3C6D) + orange (#F58B1F) theme

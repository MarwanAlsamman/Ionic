# QuizBattle — Multiplayer Real-Time Quiz Game

A fully production-ready multiplayer trivia game system built with:
- **Backend**: C# .NET 8, Clean Architecture, SignalR, EF Core InMemory
- **Frontend**: Flutter (Dart), Provider, SignalR client

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CLEAN ARCHITECTURE                       │
│                                                              │
│  Presentation Layer  (Controllers, GameHub, Middleware)      │
│          ↓                                                   │
│  Application Layer   (Services, GameManager, DTOs, AutoMapper│
│          ↓                                                   │
│  Domain Layer        (Entities, Enums, IRepository)          │
│          ↓                                                   │
│  Infrastructure      (EF Core InMemory, Repository<T>)       │
└─────────────────────────────────────────────────────────────┘
```

### Real-Time Flow
```
Flutter App ←──── SignalR ────→ .NET GameHub ────→ GameManager
    │                                                    │
    │── REST (Create User/Room) ──→ Controllers          │
    │                                                    │
    │← QuestionReceived ─────────────────────────────────┤
    │← TimerTick ────────────────────────────────────────┤
    │← RoundEnded ───────────────────────────────────────┤
    │← GameEnded ────────────────────────────────────────┤
    │                                                    │
    │── SubmitAnswer ────────────────────────────────────→
```

---

## Backend Structure

```
backend/QuizGameApi/
├── Domain/
│   ├── Entities/        (User, GameRoom, Player, Question, GameRound, PlayerAnswer)
│   ├── Enums/           (GameStatus, Difficulty)
│   └── Interfaces/      (IRepository<T>)
├── Application/
│   ├── DTOs/            (Request/Response DTOs)
│   ├── Interfaces/      (IUserService, IGameRoomService, IGameManager)
│   ├── Services/        (UserService, GameRoomService, GameManager)
│   └── Mappings/        (AutoMapper profile)
├── Infrastructure/
│   ├── Data/            (QuizGameDbContext, DataSeeder — 32 questions)
│   └── Repositories/    (Repository<T> — generic EF Core implementation)
└── Presentation/
    ├── Controllers/     (UserController, GameRoomController)
    ├── Hubs/            (GameHub — SignalR)
    └── Middleware/      (LoggingMiddleware, ExceptionHandlingMiddleware)
```

## Flutter Structure

```
flutter_app/quiz_game/lib/
├── core/
│   ├── constants/       (AppConstants — base URL, keys)
│   └── theme/           (AppTheme — dark mode)
├── data/
│   ├── models/          (UserModel, GameRoomModel, PlayerModel, QuestionModel, etc.)
│   └── services/        (ApiService — REST, SignalRService — real-time)
└── features/
    ├── providers/        (UserProvider, GameProvider)
    ├── splash/           (SplashScreen)
    ├── auth/             (LoginScreen)
    ├── home/             (HomeScreen)
    ├── game_room/        (WaitingRoomScreen)
    └── game/             (GameScreen, RoundResultScreen, LeaderboardScreen)
```

---

## Scoring System

| Action | Points |
|--------|--------|
| Correct answer | +10 |
| Speed bonus (answered in <1s) | +5 |
| Speed bonus (answered in 5s) | +2.5 |
| Wrong answer | 0 |
| No answer | 0 |

Speed bonus formula: `bonus = (1 - answerTime/totalTime) * 5`

---

## SignalR Events

### Server → Client
| Event | Data | Description |
|-------|------|-------------|
| `PlayerJoined` | `{player, totalPlayers}` | New player entered room |
| `PlayerLeft` | `{playerId, username, totalPlayers}` | Player left |
| `PlayerReady` | `{playerId, username}` | Player marked ready |
| `GameStarted` | `{totalRounds}` | Host started game |
| `QuestionReceived` | `QuestionDto` | New question (no correct answer) |
| `TimerTick` | `int` (seconds remaining) | Countdown update |
| `RoundEnded` | `RoundResultDto` | Round finished, scores revealed |
| `GameEnded` | `GameEndedDto` | Final leaderboard |
| `Error` | `string` | Error message |

### Client → Server
| Method | Args | Description |
|--------|------|-------------|
| `JoinRoom` | `roomCode, userId` | Join SignalR group |
| `PlayerReady` | `roomCode` | Mark self ready |
| `StartGame` | `roomCode` | Host starts game |
| `SubmitAnswer` | `questionId, option, timeMs` | Submit answer |
| `LeaveRoom` | — | Leave room cleanly |

---

## Prerequisites

### Backend
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)

### Flutter
- [Flutter SDK 3.2+](https://flutter.dev/docs/get-started/install)
- Android Studio / Xcode (for emulator/simulator)
- Android SDK API 21+ (for device/emulator)

---

## Run Instructions

### Step 1: Start the Backend

```bash
cd backend/QuizGameApi
dotnet restore
dotnet run
```

The API will start at `http://localhost:5000`.
Swagger UI: `http://localhost:5000/swagger`

### Step 2: Configure Flutter App

Edit `flutter_app/quiz_game/lib/core/constants/app_constants.dart`:

```dart
// For Android emulator:
static const String baseUrl = 'http://10.0.2.2:5000';

// For iOS simulator:
static const String baseUrl = 'http://localhost:5000';

// For physical device (use your machine's LAN IP):
static const String baseUrl = 'http://192.168.1.XXX:5000';
```

### Step 3: Run Flutter App

```bash
cd flutter_app/quiz_game
flutter pub get
flutter run
```

### Step 4: Build APK (Android)

```bash
cd flutter_app/quiz_game
flutter pub get
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

### Step 5: Build for iOS

```bash
flutter build ios --release
# Or open in Xcode:
open ios/Runner.xcworkspace
```

---

## Test Scenario

### Manual Testing (2 players)

1. **Player 1** (Host):
   - Launch app → Enter username "Alice" → Continue
   - Tap "Create Game" → Room code appears (e.g., `ABC123`)
   - Share the code with Player 2

2. **Player 2**:
   - Launch app → Enter username "Bob" → Continue
   - Enter room code `ABC123` → Tap "Join Now"

3. **Back to Player 1**:
   - See Bob appear in the waiting room
   - Tap "Start Game"

4. **Both players**:
   - Question appears with 4 options and a 10-second timer
   - Tap an answer → Answer submitted indicator shows
   - Round result screen shows correct answer + leaderboard
   - After all rounds: Final leaderboard with podium

### API Testing (Swagger)

```http
# 1. Create a user
POST http://localhost:5000/api/user
{"username": "Alice"}

# 2. Create a room
POST http://localhost:5000/api/gameroom/create
{"hostUserId": "GUID_FROM_STEP_1", "maxPlayers": 8, "totalQuestions": 10}

# 3. Join a room
POST http://localhost:5000/api/gameroom/join
{"roomCode": "ABC123", "userId": "ANOTHER_GUID"}

# 4. Get room details
GET http://localhost:5000/api/gameroom/ABC123
```

---

## Switching to SQL Server (Production)

Only 2 changes needed:

1. Install package:
```bash
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
```

2. In `Program.cs`, replace:
```csharp
// Before (InMemory):
opt.UseInMemoryDatabase("QuizGameDb")

// After (SQL Server):
opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))
```

3. Add connection string to `appsettings.json`:
```json
"ConnectionStrings": {
  "DefaultConnection": "Server=.;Database=QuizGameDb;Trusted_Connection=True;"
}
```

4. Run migrations:
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

---

## Questions Database

32 questions across 5 categories:
- **Science** (10) — Easy to Hard
- **Geography** (5) — Easy to Hard
- **History** (5) — Easy to Hard
- **Mathematics** (5) — Easy to Hard
- **Technology** (7) — Easy to Medium

---

## Design Patterns Used

| Pattern | Where |
|---------|-------|
| Repository Pattern | `IRepository<T>` → `Repository<T>` |
| Service Layer | `UserService`, `GameRoomService` |
| Singleton | `GameManager` (holds active game Tasks) |
| Observer | SignalR events → Provider → UI rebuild |
| Factory | `IServiceScopeFactory` for scoped DB per game round |
| Strategy | Scoring algorithm (base + speed bonus) |

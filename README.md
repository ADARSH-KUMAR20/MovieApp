# Offline-First Movie Browser (iOS)

A high-performance, offline-capable iOS application built with **SwiftUI**, **Combine**, **Core Data**, and a custom **OperationQueue** concurrency engine. The app integrates with the **OMDb API** to search movies, browse details, and save favorites for complete offline access.

---

## 🎯 Architecture Overview (MVVM + Clean Services)

The codebase strictly follows the **MVVM (Model-View-ViewModel)** architectural pattern with decoupled Service and Repository layers:

```
MovieApp/
├── Model/
│   ├── Movie.swift                         # Search feed model & OMDb response parsing
│   └── MovieDetail.swift                   # Full movie details model (ratings, cast, plot)
├── Network/
│   ├── AppConfiguration.swift              # Environment & API Key build setting resolver
│   └── MovieNetworkService.swift           # Asynchronous OMDb HTTP networking layer
├── OperationQueue/
│   ├── ImageCacheManager.swift             # Memory Cache (NSCache) & Disk Cache coordinator
│   ├── ImageDownloadOperation.swift        # Custom asynchronous concurrent Operation
│   └── ImageDownloadQueueManager.swift     # Concurrency throttle & operation lifecycle manager
├── PersistanceStorage/
│   ├── CoreDataManager/
│   │   ├── MovieDataModel.xcdatamodeld     # Core Data Managed Object Model
│   │   ├── FavoriteMovieEntity.swift       # NSManagedObject subclass with binary poster storage
│   │   └── CoreDataManager.swift          # Core Data CRUD operations & stack setup
│   └── CacheDataManager/
│       └── DiskImageCacheManager.swift     # Persistent file-system disk cache (CachesDirectory)
├── Services/
│   ├── HomeScreenServiceProtcol.swift      # Contract for search, favorites, and prefetching
│   └── HomeScreenServiceImpl.swift         # Service implementation orchestrating Network & Storage
├── ViewModel/
│   ├── MovieListViewModel.swift            # Feed state, search debounce, pagination & tabs
│   └── MovieDetailViewModel.swift          # Detail screen state management
└── View/
    ├── MovieListView.swift                 # Main feed, top switcher, search header & states
    ├── MovieDetailView.swift               # Comprehensive movie detail screen
    └── Components/
        ├── CachedAsyncImageView.swift      # Reactive image component with placeholder shimmer
        ├── MovieRowView.swift              # Modern card layout with 115x115 square thumbnail
        └── PosterDetailModal.swift         # Quick full-screen poster inspection modal
```

---

## ⚡ Custom Asynchronous Image Caching

Per the assignment requirements, **no third-party UI libraries (such as SDWebImage or Kingfisher) are used**. Instead, a custom high-performance, two-tier caching and background concurrency architecture was implemented:

### 1. Two-Tier Caching Hierarchy
1. **Tier 1 — In-Memory Cache (`NSCache`)**:
   - Fast, thread-safe memory storage (`countLimit: 150`, `totalCostLimit: ~100MB`).
   - Automatically purges in response to `UIApplication.didReceiveMemoryWarningNotification`.
2. **Tier 2 — Persistent Disk Cache (`FileManager`)**:
   - Stores image payloads under `Library/Caches/MoviePosters/`.
   - Persists across app launches and device reboots.
3. **Offline Tier — Core Data Binary Storage**:
   - Favorited movies store their poster binary data directly inside Core Data (`FavoriteMovieEntity.posterData`) with external storage support, ensuring posters load even in Airplane Mode.

### 2. OperationQueue Concurrency & Lifecycle
- **Throttled Concurrency**: Managed by `ImageDownloadQueueManager` configured with `maxConcurrentOperationCount = 4` on `.userInitiated` Quality of Service to keep the main thread smooth at 60/120 FPS.
- **Deduplication**: In-flight downloads are tracked in an active operations registry. Duplicate requests attach to the ongoing operation rather than triggering redundant network calls.
- **Scroll Cancellation**: When a row scrolls off the screen, `CachedAsyncImageView.onDisappear` automatically calls `cancelDownload()`, freeing queue capacity for visible rows.
- **Strict 10-Item Batching**: Only 10 movies and their 10 corresponding poster operations are queued at a time. The app does not download arbitrary large quantities upfront.

---

## 💾 Offline Mode & Local Persistence (Core Data)

- **Storage**: Powered by **Core Data** with an optimized `NSPersistentContainer` (`MovieDataModel.xcdatamodeld`).
- **Single Source of Truth**: When a user marks a movie as favorite, the `HomeScreenServiceImpl` immediately commits the record and poster binary to Core Data.
- **Offline Favorites Tab**: The top switcher on the home screen allows instantaneous switching between **All Movies** and **Favorites**. In Favorites mode, all data is read directly from local Core Data, allowing the user to browse their saved library with zero active network connection.

---

## 🔍 Features & UX Resilience

- **Search & Feed**:
  - Automatically loads 10 random movies on launch so the user is never greeted with a blank screen.
  - Interactive search bar with a 500ms debounce to minimize API chatter.
  - Pagination automatically requests 10 more movies as the user scrolls near the bottom of the feed.
- **Movie Details**:
  - Full-screen detail presentation showing ratings (IMDb & Metascore), release year, runtime, full plot summary, cast & crew, awards, and box office.
  - Detail screen includes a navigation bar heart button to toggle favorites.
- **Error & Loading States**:
  - Animated activity indicators during network operations.
  - Resilient error handling with user-friendly retry buttons for connectivity drops.

---

## 🛠️ Requirements & How to Run

### Prerequisites
- macOS Sonoma (or newer)
- Xcode 16.0 or later
- iOS 17.0+ Simulator or physical device

### Running the App
1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd MovieApp
   ```
2. Open the project in Xcode:
   ```bash
   open MovieApp.xcodeproj
   ```
3. Select an iOS Simulator (e.g. **iPhone 16 Pro** or **iPhone 16e**).
4. Press **⌘ + R** (or click the **Play** button in Xcode) to build and run.

### API Key Configuration
The OMDb API key is configured as a user-defined build setting:
- **Build Setting**: `API_KEY = 4bf9b0d2`
- **Info.plist**: Dynamically references `$(API_KEY)` at compile time and is accessed in Swift via `AppConfiguration.apiKey`.

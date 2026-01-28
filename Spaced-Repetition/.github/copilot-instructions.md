# Spaced Repetition App - Architecture Documentation

## Overview

This is an iOS/macOS app built with **SwiftUI**, **SwiftData**, and **The Composable Architecture (TCA)** to help users improve long-term memory using the **Spaced Repetition** learning technique.

---

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Architecture:** The Composable Architecture (TCA) by Point-Free
- **Data Persistence:** SwiftData
- **Minimum Target:** iOS 17+ / macOS 14+
- **Package Manager:** Swift Package Manager (SPM)

---

## Dependencies

```swift
// Package.swift or via Xcode SPM
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0")
]
```

---

## Project Structure

```
Spaced-Repetition/
├── Spaced-Repetition/
│   ├── App/
│   │   └── Spaced_RepetitionApp.swift       # App entry point
│   ├── Features/
│   │   ├── App/
│   │   │   ├── AppFeature.swift             # Root feature reducer
│   │   │   └── AppView.swift                # Root view with TabView
│   │   ├── StudyItems/
│   │   │   ├── StudyItemsFeature.swift      # Study items list reducer
│   │   │   ├── StudyItemsView.swift         # Study items list view
│   │   │   ├── AddStudyItemFeature.swift    # Add item reducer
│   │   │   ├── AddStudyItemView.swift       # Add item view
│   │   │   ├── StudyItemDetailFeature.swift # Item detail reducer
│   │   │   └── StudyItemDetailView.swift    # Item detail view
│   │   ├── Review/
│   │   │   ├── ReviewFeature.swift          # Single review reducer
│   │   │   ├── ReviewView.swift             # Single review view
│   │   │   ├── ReviewQueueFeature.swift     # Review queue reducer
│   │   │   └── ReviewQueueView.swift        # Review queue view
│   │   └── Stats/
│   │       ├── StatsFeature.swift           # Statistics reducer
│   │       └── StatsView.swift              # Statistics view
│   ├── Models/
│   │   ├── StudyItem.swift                  # SwiftData model
│   │   └── ReviewSession.swift              # SwiftData model
│   ├── Services/
│   │   ├── DatabaseClient.swift             # SwiftData dependency
│   │   ├── NotificationClient.swift         # Push notifications dependency
│   │   └── SpacedRepetitionClient.swift     # SM-2 algorithm dependency
│   └── Assets.xcassets/
├── Spaced-RepetitionTests/                  # Unit tests
└── Spaced-RepetitionUITests/                # UI tests
```

---

## The Composable Architecture (TCA) Pattern

### Core Concepts

TCA is built around these key concepts:

1. **State:** A type that describes the data your feature needs to perform its logic and render its UI.
2. **Action:** A type that represents all actions that can happen in your feature (user actions, notifications, etc.).
3. **Reducer:** A function that describes how to evolve the current state to the next state given an action.
4. **Store:** The runtime that actually drives your feature. You send actions to the store and observe state changes.
5. **Effect:** A type that represents side effects (API calls, database operations, etc.).

### Feature Example

```swift
import ComposableArchitecture
import SwiftData

@Reducer
struct StudyItemsFeature {
    @ObservableState
    struct State: Equatable {
        var items: IdentifiedArrayOf<StudyItemState> = []
        var isLoading: Bool = false
        @Presents var destination: Destination.State?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case itemsLoaded([StudyItem])
        case addItemTapped
        case deleteItem(id: UUID)
        case itemTapped(StudyItemState)
        case destination(PresentationAction<Destination.Action>)
    }
    
    @Reducer
    enum Destination {
        case detail(StudyItemDetailFeature)
        case addItem(AddStudyItemFeature)
    }
    
    @Dependency(\.databaseClient) var databaseClient
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let items = try await databaseClient.fetchStudyItems()
                    await send(.itemsLoaded(items))
                }
                
            case let .itemsLoaded(items):
                state.isLoading = false
                state.items = IdentifiedArray(uniqueElements: items.map { StudyItemState(from: $0) })
                return .none
                
            // ... other cases
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
```

### View Example

```swift
import SwiftUI
import ComposableArchitecture

struct StudyItemsView: View {
    @Bindable var store: StoreOf<StudyItemsFeature>
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.items) { item in
                    StudyItemRow(item: item)
                        .onTapGesture {
                            store.send(.itemTapped(item))
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        store.send(.deleteItem(id: store.items[index].id))
                    }
                }
            }
            .navigationTitle("Study Items")
            .toolbar {
                Button {
                    store.send(.addItemTapped)
                } label: {
                    Image(systemName: "plus")
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
        .sheet(item: $store.scope(state: \.destination?.addItem, action: \.destination.addItem)) { store in
            AddStudyItemView(store: store)
        }
    }
}
```

---

## Dependencies (Side Effects)

### Database Client with CloudKit Sync

The app uses SwiftData with CloudKit for automatic multi-device sync. Data updates are propagated using AsyncStream for real-time reactivity.

```swift
struct DatabaseClient: Sendable {
    // Standard CRUD operations
    var fetchStudyItems: @Sendable () async throws -> [StudyItemState]
    var fetchStudyItem: @Sendable (_ id: UUID) async throws -> StudyItemState?
    var saveStudyItem: @Sendable (_ item: StudyItemState) async throws -> Void
    var deleteStudyItem: @Sendable (_ id: UUID) async throws -> Void
    var updateStudyItem: @Sendable (_ item: StudyItemState) async throws -> Void
    var fetchDueItems: @Sendable () async throws -> [StudyItemState]
    var saveReviewSession: @Sendable (_ itemId: UUID, _ quality: Int, _ responseTime: TimeInterval) async throws -> Void
    var fetchReviewSessions: @Sendable (_ itemId: UUID) async throws -> [ReviewSessionState]
    
    // AsyncStream for real-time updates (CloudKit sync)
    var studyItemsStream: @Sendable () -> AsyncStream<[StudyItemState]>
}
```

### Using AsyncStream in Reducers

Subscribe to the stream on `onAppear` and cancel on `onDisappear`:

```swift
case .onAppear:
    state.isLoading = true
    return .send(.subscribeToItems)

case .subscribeToItems:
    return .run { send in
        let stream = databaseClient.studyItemsStream()
        for await items in stream {
            await send(.streamUpdated(items))
        }
    }
    .cancellable(id: "itemsStream", cancelInFlight: true)

case let .streamUpdated(items):
    state.isLoading = false
    state.items = IdentifiedArray(uniqueElements: items)
    return .none

case .onDisappear:
    return .cancel(id: "itemsStream")
```

### CloudKit Configuration

The `SharedModelContainer` configures SwiftData with CloudKit:

```swift
let config = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .automatic  // Enable CloudKit sync
)
```

Changes from other devices are detected via `NSPersistentStoreRemoteChangeNotification` and propagated to all subscribers.

extension DatabaseClient: DependencyKey {
    static let liveValue: DatabaseClient = { /* SwiftData implementation */ }()
    static let testValue = DatabaseClient()
    static let previewValue = DatabaseClient(/* Mock data */)
}

extension DependencyValues {
    var databaseClient: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}
```

### Spaced Repetition Client

```swift
@DependencyClient
struct SpacedRepetitionClient: Sendable {
    var calculateNextReview: @Sendable (_ easeFactor: Double, _ interval: Int, _ quality: Int) -> ReviewResult
}

extension SpacedRepetitionClient: DependencyKey {
    static let liveValue = SpacedRepetitionClient(
        calculateNextReview: { easeFactor, interval, quality in
            // SM-2 Algorithm Implementation
            let newEaseFactor = max(1.3, easeFactor + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02)))
            
            let newInterval: Int
            if quality < 3 {
                newInterval = 1
            } else if interval == 0 {
                newInterval = 1
            } else if interval == 1 {
                newInterval = 6
            } else {
                newInterval = Int(Double(interval) * newEaseFactor)
            }
            
            let nextDate = Calendar.current.date(byAdding: .day, value: newInterval, to: Date())!
            return ReviewResult(nextDate: nextDate, newInterval: newInterval, newEaseFactor: newEaseFactor)
        }
    )
}
```

---

## Core Concept: Spaced Repetition Method

### What is Spaced Repetition?

Spaced Repetition is a learning technique that involves reviewing material at **increasing intervals** (e.g., 1 day, 3 days, 1 week, 2 weeks, etc.) just before you forget. This method strengthens neural pathways through active recall.

### Spacing Schedule

| Review | Interval |
|--------|----------|
| 1st    | Within 24 hours of learning |
| 2nd    | 1 day |
| 3rd    | 3 days |
| 4th    | 7 days (1 week) |
| 5th    | 14 days (2 weeks) |
| 6th    | 30 days (1 month) |

**Note:** Intervals should be adjusted based on user performance:
- **Struggling?** → Shorten intervals
- **Easy?** → Lengthen intervals

### Optimal Review Times

| Time Period | Best For |
|-------------|----------|
| Morning (9 AM) | Immediate recall performance |
| Afternoon/Evening (4 PM - 9 PM) | Long-term memory consolidation |
| Before Sleep | Memory consolidation into long-term storage |

---

## App Features

### Current Features

- ✅ Store and manage study items with title, content, images, and tags
- ✅ SwiftData persistence
- ✅ Review queue for due items
- ✅ SM-2 spaced repetition algorithm
- ✅ Quality rating system (0-5)
- ✅ Statistics and progress tracking
- ✅ Learning tips
- ✅ Push notifications for review reminders
- ✅ Daily reminder scheduling at optimal times (6 PM)
- ✅ Review timer to track response time
- ✅ Hint system during reviews
- ✅ Memory tips throughout the app
- ✅ Streak tracking for motivation
- ✅ Progress visualization
- ✅ Upcoming reviews forecast

### UX Components

The app includes several reusable UX components in `Shared/Components/`:

1. **MemoryTipCard** - Displays memory tips categorized by Timing, Technique, Science, Habit, Wellness
2. **StreakCard** - Shows current streak, best streak, and today's status
3. **ReviewTimer** - Live timer during reviews with color-coded response time feedback
4. **ProgressRing** - Circular progress indicator for daily completion
5. **DailyProgressCard** - Shows today's review progress
6. **WeeklyProgressView** - Bar chart showing weekly review activity

### App Tabs

1. **Items Tab:** Browse, add, edit, and delete study items
2. **Review Tab:** Review queue for due items with progress tracking
3. **Stats Tab:** View statistics, card distribution, and learning tips

---

## Data Models

### StudyItem

```swift
@Model
final class StudyItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    @Attribute(.externalStorage) var imageData: Data?
    var pdfURL: URL?
    var createdAt: Date
    var nextReviewDate: Date
    var reviewCount: Int
    var easeFactor: Double  // Default: 2.5
    var interval: Int       // Days until next review
    var tags: [String]
}
```

### ReviewSession

```swift
@Model
final class ReviewSession {
    @Attribute(.unique) var id: UUID
    var itemId: UUID
    var reviewedAt: Date
    var quality: Int        // 0-5 rating
    var responseTime: TimeInterval
}
```

### StudyItemState (TCA Value Type)

```swift
struct StudyItemState: Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var content: String
    var imageData: Data?
    var nextReviewDate: Date
    var reviewCount: Int
    var easeFactor: Double
    var interval: Int
    var tags: [String]
    
    var isDue: Bool { nextReviewDate <= Date() }
    var daysUntilReview: Int { /* calculated */ }
}
```

---

## Spaced Repetition Algorithm

The app implements the **SM-2 (SuperMemo 2) algorithm**:

### SM-2 Algorithm

```
EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))

Where:
- EF = Ease Factor (minimum 1.3)
- q = Quality of response (0-5)
- EF' = New Ease Factor
```

**Quality Ratings:**
- 0: Complete blackout
- 1: Incorrect, but remembered upon seeing answer
- 2: Incorrect, but answer seemed easy to recall
- 3: Correct with serious difficulty
- 4: Correct with some hesitation
- 5: Perfect response

**Interval Calculation:**
- Quality < 3: Reset to 1 day
- First successful review: 1 day
- Second successful review: 6 days
- Subsequent: interval × easeFactor

---

## Testing with TCA

TCA provides excellent testing support through `TestStore`:

```swift
import ComposableArchitecture
import XCTest

@MainActor
final class StudyItemsFeatureTests: XCTestCase {
    func testLoadItems() async {
        let mockItems = [StudyItem(title: "Test", content: "Content")]
        
        let store = TestStore(initialState: StudyItemsFeature.State()) {
            StudyItemsFeature()
        } withDependencies: {
            $0.databaseClient.fetchStudyItems = { mockItems }
        }
        
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        
        await store.receive(\.itemsLoaded) {
            $0.isLoading = false
            $0.items = IdentifiedArray(uniqueElements: mockItems.map { StudyItemState(from: $0) })
        }
    }
}
```

---

## Key Techniques for Users

1. **Active Recall:** Test yourself rather than passively rereading
2. **Varied Context:** Review in different contexts for stronger memories
3. **Consistent Schedule:** Don't cram; spread reviews over time
4. **Sleep:** Use sleep for memory consolidation

---

## Development Guidelines

### Code Style
- Use TCA conventions for feature organization
- One feature = one Reducer + one View
- Use `@DependencyClient` for all side effects
- Keep reducers pure and testable
- Use `IdentifiedArray` for collections
- Use value types (structs) for TCA State, convert from/to SwiftData models
- **Swift 6 Compatibility:** Use `var body: some Reducer<State, Action>` instead of `var body: some ReducerOf<Self>` to avoid circular reference issues with TCA macros
- Avoid putting non-Equatable types (like `PhotosPickerItem`) in TCA State; handle them in the View layer with `@State`

### Testing
- Write unit tests for all reducers using `TestStore`
- Test all action paths and state mutations
- Mock dependencies for isolated testing
- Use `XCTUnimplemented` for unimplemented test dependencies

### Performance
- Use `@ObservableState` for efficient SwiftUI updates
- Lazy load images and PDFs
- Use `@Shared` for cross-feature state sharing when needed
- Implement proper cancellation for long-running effects

---

## Future Considerations

- **Widgets:** Home screen widgets for quick review access
- **Shortcuts Integration:** Siri shortcuts for voice-based reviews
- **Watch App:** Quick review sessions on Apple Watch
- **Share Extension:** Import content from other apps
- **Export:** Export learning data and progress reports
- **PDF Support:** Import and review PDF documents
- **AI-Powered Quizzes:** Premium feature for auto-generated questions

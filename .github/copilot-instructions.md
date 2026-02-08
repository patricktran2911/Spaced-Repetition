# Copilot Instructions for Spaced-Repetition Project

## General Rules

1. Do not document .md file if I don't prompt it

## SwiftUI & TCA Architecture Rules

### 1. Never Use @State
- **NEVER** use `@State` in views
- All state must be managed through TCA (The Composable Architecture) Feature's `State` struct
- Use `@Bindable var store: StoreOf<Feature>` for view state access
- Local UI-only state should still be moved to the Feature for consistency and testability

### 2. Break Down Views to Simple Primitive Data
- Break all views down until they only have very simple data state
- Views should only receive primitive types as parameters: `String`, `Int`, `Double`, `Bool`, `Date`, etc.
- Complex data should be broken down into smaller components that each receive simple primitives
- Example:
  ```swift
  // ❌ Bad - View receives complex type
  struct ItemCard: View {
      let item: StudyItemState
  }
  
  // ✅ Good - View receives primitives
  struct ItemCard: View {
      let title: String
      let content: String
      let reviewCount: Int
      let isDue: Bool
  }
  ```

### 3. Reusable Components in Components Folder
- All reusable views must be placed in the `Shared/Components/` folder
- Each reusable component should have its own folder
- Structure:
  ```
  Shared/
    Components/
      ProgressRing/
        ProgressRing.swift
      StreakCard/
        StreakCard.swift
      FlowLayout/
        FlowLayout.swift
  ```

### 4. Folder Structure as Inheritance
- Use folders to organize each View and Feature
- Folder structure should reflect inheritance/hierarchy
- Each Feature has its own folder containing:
  - Feature reducer file
  - View file
  - Components specific to that feature
- Structure example:
  ```
  Features/
    App/
      AppFeature.swift
      AppView.swift
    StudyItems/
      StudyItemsFeature.swift
      StudyItemsView.swift
      StudyItemDetail/
        StudyItemDetailFeature.swift
        StudyItemDetailView.swift
        Components/
          ReviewStatusCard.swift
          EditableSectionCard.swift
      AddStudyItem/
        AddStudyItemFeature.swift
        AddStudyItemView.swift
    Review/
      ReviewFeature.swift
      ReviewView.swift
      ReviewQueue/
        ReviewQueueFeature.swift
        ReviewQueueView.swift
  ```

## Code Style

- Use Swift's modern concurrency (async/await)
- Prefer value types (structs) over reference types (classes)
- Use `@ObservableState` macro for TCA state
- Use `@Reducer` macro for TCA reducers
- Keep reducers focused and compose them when needed

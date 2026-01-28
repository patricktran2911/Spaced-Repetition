//
//  AppView.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        TabView(selection: $store.selectedTab) {
            StudyItemsView(
                store: store.scope(state: \.studyItems, action: \.studyItems)
            )
            .tabItem {
                Label(AppFeature.State.Tab.items.rawValue, systemImage: AppFeature.State.Tab.items.icon)
            }
            .tag(AppFeature.State.Tab.items)
            
            LectureReviewView(
                store: store.scope(state: \.lectureReview, action: \.lectureReview)
            )
            .tabItem {
                Label(AppFeature.State.Tab.review.rawValue, systemImage: AppFeature.State.Tab.review.icon)
            }
            .tag(AppFeature.State.Tab.review)
            .badge(store.lectureReview.dueCount)
            
            StatsView(
                store: store.scope(state: \.stats, action: \.stats)
            )
            .tabItem {
                Label(AppFeature.State.Tab.stats.rawValue, systemImage: AppFeature.State.Tab.stats.icon)
            }
            .tag(AppFeature.State.Tab.stats)
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.databaseClient = .previewValue
        }
    )
}
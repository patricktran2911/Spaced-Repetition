//
//  StatsView.swift
//  Spaced-Repetition
//
//  Created by Patrick Tran on 1/20/26.
//

import SwiftUI
import ComposableArchitecture

struct StatsView: View {
    @Bindable var store: StoreOf<StatsFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if store.isLoading {
                    ProgressView()
                        .padding(.top, 50)
                } else {
                    VStack(spacing: 20) {
                        // Overview Cards
                        overviewSection
                        
                        // Upcoming Reviews
                        upcomingReviewsSection
                        
                        // Card Distribution
                        cardDistributionSection
                        
                        // Tips Section
                        tipsSection
                    }
                    .padding()
                    #if os(iOS)
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 900 : .infinity)
                    #endif
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Statistics")
            .refreshable {
                store.send(.refreshStats)
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        #if os(iOS)
        let columns = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        #else
        let columns = 2
        #endif
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
        
        return LazyVGrid(columns: gridItems, spacing: 12) {
            StatCard(
                title: "Total Items",
                value: "\(store.totalItems)",
                icon: "book.fill",
                color: .blue
            )
            
            StatCard(
                title: "Due Today",
                value: "\(store.dueToday)",
                icon: "clock.fill",
                color: store.dueToday > 0 ? .orange : .green
            )
            
            StatCard(
                title: "Total Reviews",
                value: "\(store.totalReviews)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Avg. Ease",
                value: String(format: "%.2f", store.averageEaseFactor),
                icon: "speedometer",
                color: .purple
            )
        }
    }
    
    // MARK: - Upcoming Reviews Section
    private var upcomingReviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Reviews")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.upcomingReviews) { review in
                        VStack(spacing: 4) {
                            Text("\(review.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(review.count > 0 ? .primary : .secondary)
                            
                            Text(review.dayLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 60, height: 70)
                        .background(review.count > 0 ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
    
    // MARK: - Card Distribution Section
    private var cardDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Distribution")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(store.itemsByInterval) { group in
                    HStack {
                        Circle()
                            .fill(colorForGroup(group.color))
                            .frame(width: 12, height: 12)
                        
                        Text(group.label)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(group.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        let total = store.itemsByInterval.reduce(0) { $0 + $1.count }
                        let width = total > 0 ? CGFloat(group.count) / CGFloat(total) * geometry.size.width : 0
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForGroup(group.color).opacity(0.3))
                            .frame(height: 8)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(colorForGroup(group.color))
                                    .frame(width: width, height: 8)
                            }
                    }
                    .frame(height: 8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Learning Tip")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    store.send(.nextTipTapped)
                } label: {
                    Label("Next", systemImage: "arrow.right.circle")
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: store.selectedTip.icon)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text(store.selectedTip.title)
                        .font(.headline)
                }
                
                Text(store.selectedTip.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func colorForGroup(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        default: return .gray
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    StatsView(
        store: Store(
            initialState: StatsFeature.State(
                totalItems: 25,
                dueToday: 5,
                reviewedToday: 3,
                totalReviews: 150,
                averageEaseFactor: 2.35,
                itemsByInterval: [
                    .init(label: "New", count: 5, color: "blue"),
                    .init(label: "Learning", count: 8, color: "orange"),
                    .init(label: "Young", count: 7, color: "yellow"),
                    .init(label: "Mature", count: 5, color: "green")
                ]
            )
        ) {
            StatsFeature()
        }
    )
}

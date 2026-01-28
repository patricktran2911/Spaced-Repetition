//
//  ProgressRing.swift
//  Spaced-Repetition
//
//  Circular progress indicator for review completion
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let total: Int
    let completed: Int
    var size: CGFloat = 120
    var lineWidth: CGFloat = 12
    var showLabel: Bool = true
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.blue, .green, .blue]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Label
            if showLabel {
                VStack(spacing: 2) {
                    Text("\(completed)")
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    Text("of \(total)")
                        .font(.system(size: size * 0.12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Daily Progress Card
struct DailyProgressCard: View {
    let dueToday: Int
    let completedToday: Int
    
    var progress: Double {
        guard dueToday > 0 else { return 1.0 }
        return Double(completedToday) / Double(dueToday + completedToday)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            ProgressRing(
                progress: progress,
                total: dueToday + completedToday,
                completed: completedToday,
                size: 80,
                lineWidth: 8
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Progress")
                    .font(.headline)
                
                if dueToday == 0 && completedToday == 0 {
                    Text("No items to review")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if dueToday == 0 {
                    Text("All done! 🎉")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                } else {
                    Text("\(dueToday) items remaining")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
                
                if completedToday > 0 {
                    Text("\(completedToday) reviewed today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Weekly Progress View
struct WeeklyProgressView: View {
    let dailyData: [(day: String, count: Int)]
    
    var maxCount: Int {
        max(dailyData.map(\.count).max() ?? 1, 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(dailyData, id: \.day) { data in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(data.count > 0 ? Color.green : Color(.systemGray5))
                            .frame(height: CGFloat(data.count) / CGFloat(maxCount) * 60 + 4)
                        
                        Text(data.day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressRing(progress: 0.7, total: 10, completed: 7)
        
        DailyProgressCard(dueToday: 5, completedToday: 3)
        DailyProgressCard(dueToday: 0, completedToday: 8)
        
        WeeklyProgressView(dailyData: [
            ("Mon", 5),
            ("Tue", 8),
            ("Wed", 3),
            ("Thu", 12),
            ("Fri", 0),
            ("Sat", 6),
            ("Sun", 2)
        ])
    }
    .padding()
}

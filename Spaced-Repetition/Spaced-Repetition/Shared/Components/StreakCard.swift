//
//  StreakCard.swift
//  Spaced-Repetition
//
//  Motivational streak tracking component
//

import SwiftUI

struct StreakCard: View {
    let currentStreak: Int
    let bestStreak: Int
    let reviewedToday: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                // Current Streak
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(streakColor)
                        Text("Current Streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentStreak)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(streakColor)
                        Text("days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Best Streak
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Best")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(bestStreak)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Today's Status
            HStack {
                Image(systemName: reviewedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(reviewedToday ? .green : .secondary)
                
                Text(reviewedToday ? "You've reviewed today! 🎉" : "Review today to keep your streak!")
                    .font(.subheadline)
                    .foregroundStyle(reviewedToday ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(reviewedToday ? Color.green.opacity(0.1) : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var streakColor: Color {
        if currentStreak == 0 {
            return .gray
        } else if currentStreak < 7 {
            return .orange
        } else if currentStreak < 30 {
            return .red
        } else {
            return .purple
        }
    }
}

// MARK: - Motivational Messages
struct MotivationalMessage: View {
    let streak: Int
    let reviewedToday: Bool
    
    var message: String {
        if !reviewedToday {
            return "Don't break your streak! Review now to keep going."
        }
        
        switch streak {
        case 0:
            return "Start your learning journey today!"
        case 1:
            return "Great start! Day 1 complete. 🌱"
        case 2...6:
            return "Building momentum! Keep it up! 💪"
        case 7:
            return "One week streak! You're on fire! 🔥"
        case 8...13:
            return "Impressive dedication! 🌟"
        case 14:
            return "Two weeks! Your memory is growing stronger! 🧠"
        case 15...29:
            return "Amazing consistency! You're a learning machine! 🚀"
        case 30:
            return "ONE MONTH! You're unstoppable! 🏆"
        case 31...59:
            return "Legend status! Keep the streak alive! ⭐"
        case 60...89:
            return "Two months of dedication! Incredible! 🎯"
        case 90...364:
            return "You're mastering the art of learning! 🎓"
        default:
            return "Over a year! You're a learning champion! 👑"
        }
    }
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakCard(currentStreak: 7, bestStreak: 14, reviewedToday: true)
        StreakCard(currentStreak: 3, bestStreak: 14, reviewedToday: false)
        StreakCard(currentStreak: 0, bestStreak: 14, reviewedToday: false)
    }
    .padding()
}

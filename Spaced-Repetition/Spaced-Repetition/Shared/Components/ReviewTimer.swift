//
//  ReviewTimer.swift
//  Spaced-Repetition
//
//  Timer component for tracking review response time
//

import SwiftUI

struct ReviewTimer: View {
    let startTime: Date
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .foregroundStyle(.secondary)
            
            Text(formatTime(elapsed))
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(timerColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private var timerColor: Color {
        if elapsed < 5 {
            return .green
        } else if elapsed < 15 {
            return .primary
        } else if elapsed < 30 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", seconds)
        }
    }
    
    private func startTimer() {
        elapsed = Date().timeIntervalSince(startTime)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Response Time Indicator
struct ResponseTimeIndicator: View {
    let responseTime: TimeInterval
    
    var rating: ResponseTimeRating {
        if responseTime < 5 {
            return .instant
        } else if responseTime < 10 {
            return .quick
        } else if responseTime < 20 {
            return .moderate
        } else if responseTime < 40 {
            return .slow
        } else {
            return .veryLow
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: rating.icon)
            Text(rating.label)
        }
        .font(.caption)
        .foregroundStyle(rating.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(rating.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

enum ResponseTimeRating {
    case instant, quick, moderate, slow, veryLow
    
    var label: String {
        switch self {
        case .instant: return "Instant"
        case .quick: return "Quick"
        case .moderate: return "Good"
        case .slow: return "Slow"
        case .veryLow: return "Needs Work"
        }
    }
    
    var icon: String {
        switch self {
        case .instant: return "bolt.fill"
        case .quick: return "hare.fill"
        case .moderate: return "checkmark"
        case .slow: return "tortoise.fill"
        case .veryLow: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .instant: return .purple
        case .quick: return .green
        case .moderate: return .blue
        case .slow: return .orange
        case .veryLow: return .red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ReviewTimer(startTime: Date().addingTimeInterval(-5))
        ReviewTimer(startTime: Date().addingTimeInterval(-25))
        ReviewTimer(startTime: Date().addingTimeInterval(-65))
        
        Divider()
        
        ResponseTimeIndicator(responseTime: 3)
        ResponseTimeIndicator(responseTime: 8)
        ResponseTimeIndicator(responseTime: 15)
        ResponseTimeIndicator(responseTime: 30)
        ResponseTimeIndicator(responseTime: 60)
    }
    .padding()
}

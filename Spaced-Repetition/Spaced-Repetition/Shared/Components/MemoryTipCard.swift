//
//  MemoryTipCard.swift
//  Spaced-Repetition
//
//  Memory tips to help users with long-term retention
//

import SwiftUI

struct MemoryTipCard: View {
    let tip: MemoryTip
    var showDismiss: Bool = false
    var onDismiss: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tip.icon)
                    .font(.title3)
                    .foregroundStyle(tip.color)
                    .frame(width: 36, height: 36)
                    .background(tip.color.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tip.category.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                if showDismiss {
                    Button {
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Text(tip.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Memory Tip Model
struct MemoryTip: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let category: String
    
    static let tips: [MemoryTip] = [
        // Timing Tips
        MemoryTip(
            title: "Review Before Sleep",
            description: "Reviewing material before bed helps your brain consolidate memories during sleep. Your brain processes and strengthens new information while you rest.",
            icon: "moon.stars.fill",
            color: .purple,
            category: "Timing"
        ),
        MemoryTip(
            title: "Morning for Recall",
            description: "Morning reviews (around 9 AM) are great for testing your recall. Your mind is fresh and can better identify what needs more practice.",
            icon: "sunrise.fill",
            color: .orange,
            category: "Timing"
        ),
        MemoryTip(
            title: "Evening for Consolidation",
            description: "Afternoon/evening (4-9 PM) is optimal for learning new material. Long-term memory activity peaks during this time.",
            icon: "sunset.fill",
            color: .pink,
            category: "Timing"
        ),
        
        // Technique Tips
        MemoryTip(
            title: "Active Recall",
            description: "Always try to recall the answer before revealing it. The struggle to remember actually strengthens the memory trace.",
            icon: "brain.head.profile",
            color: .blue,
            category: "Technique"
        ),
        MemoryTip(
            title: "Spaced Repetition Works",
            description: "Reviewing at increasing intervals (1 day → 3 days → 1 week → 2 weeks) is proven to be 200% more effective than massed study.",
            icon: "clock.arrow.circlepath",
            color: .green,
            category: "Science"
        ),
        MemoryTip(
            title: "Create Mental Images",
            description: "Visualize what you're learning. Creating vivid mental pictures makes information much easier to recall later.",
            icon: "eye.fill",
            color: .cyan,
            category: "Technique"
        ),
        MemoryTip(
            title: "Connect to What You Know",
            description: "Link new information to existing knowledge. The more connections you make, the stronger the memory becomes.",
            icon: "link",
            color: .indigo,
            category: "Technique"
        ),
        MemoryTip(
            title: "Teach Someone Else",
            description: "Explaining concepts to others (or pretending to) forces deep processing and reveals gaps in your understanding.",
            icon: "person.2.fill",
            color: .teal,
            category: "Technique"
        ),
        
        // Consistency Tips
        MemoryTip(
            title: "Small Daily Sessions",
            description: "15-20 minutes daily beats 2-hour weekly sessions. Consistency is key for building lasting memories.",
            icon: "calendar.badge.clock",
            color: .mint,
            category: "Habit"
        ),
        MemoryTip(
            title: "Don't Skip Due Items",
            description: "Reviewing when items are due is crucial. Missing the optimal window makes relearning harder.",
            icon: "bell.badge.fill",
            color: .red,
            category: "Habit"
        ),
        
        // Wellness Tips
        MemoryTip(
            title: "Sleep is Essential",
            description: "Getting 7-8 hours of sleep is crucial for memory consolidation. Sleep-deprived learning is nearly ineffective.",
            icon: "bed.double.fill",
            color: .purple,
            category: "Wellness"
        ),
        MemoryTip(
            title: "Stay Hydrated",
            description: "Your brain is 75% water. Even mild dehydration can impair memory and concentration.",
            icon: "drop.fill",
            color: .blue,
            category: "Wellness"
        ),
        MemoryTip(
            title: "Take Breaks",
            description: "The Pomodoro technique (25 min work, 5 min break) prevents mental fatigue and improves retention.",
            icon: "timer",
            color: .orange,
            category: "Wellness"
        ),
    ]
    
    static func random() -> MemoryTip {
        tips.randomElement()!
    }
    
    static func forCategory(_ category: String) -> [MemoryTip] {
        tips.filter { $0.category == category }
    }
}

#Preview {
    VStack(spacing: 16) {
        MemoryTipCard(tip: .tips[0])
        MemoryTipCard(tip: .tips[3], showDismiss: true)
    }
    .padding()
}

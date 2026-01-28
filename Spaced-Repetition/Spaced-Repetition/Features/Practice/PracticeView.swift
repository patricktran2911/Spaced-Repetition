import SwiftUI
import ComposableArchitecture

struct PracticeView: View {
    @Bindable var store: StoreOf<PracticeFeature>
    @State private var dragOffset: CGFloat = 0
    @State private var cardRotation: Double = 0
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Practice")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarItems }
                .onAppear { _ = store.send(.onAppear) }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            ProgressView("Loading cards...")
        } else if store.items.isEmpty {
            EmptyPracticeView(mode: store.practiceMode)
        } else if let item = store.currentItem {
            VStack(spacing: 0) {
                PracticeProgressHeader(current: store.currentIndex + 1, total: store.items.count, progress: store.progress)
                    .padding()
                Spacer()
                PracticeFlashcard(item: item, isFlipped: store.isFlipped, dragOffset: dragOffset, rotation: cardRotation)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { _ = store.send(.flipCard) }
                    }
                    .gesture(cardDragGesture)
                    .padding()
                Spacer()
                hintText
                if store.isFlipped { actionButtons }
                navigationButtons
            }
        } else {
            PracticeCompleteView { _ = store.send(.restartPractice) }
        }
    }
    
    private var cardDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
                cardRotation = Double(value.translation.width / 20)
            }
            .onEnded { value in
                withAnimation(.spring()) {
                    if value.translation.width > 100 { _ = store.send(.knowIt) }
                    else if value.translation.width < -100 { _ = store.send(.needsWork) }
                    dragOffset = 0
                    cardRotation = 0
                }
            }
    }
    
    @ViewBuilder
    private var hintText: some View {
        if !store.isFlipped {
            Text("Tap to reveal answer").font(.caption).foregroundStyle(.secondary)
        } else {
            Text("Swipe right if you know it, left if you need more practice")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 40) {
            Button { withAnimation(.spring()) { _ = store.send(.needsWork) } } label: {
                VStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 50)).foregroundStyle(.red)
                    Text("Needs Work").font(.caption).foregroundStyle(.secondary)
                }
            }
            Button { withAnimation(.spring()) { _ = store.send(.knowIt) } } label: {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 50)).foregroundStyle(.green)
                    Text("Know It").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 20)
    }
    
    private var navigationButtons: some View {
        HStack {
            Button { _ = store.send(.previousCard) } label: { Image(systemName: "chevron.left").font(.title2).padding() }
                .disabled(store.currentIndex == 0)
            Spacer()
            Button { _ = store.send(.nextCard) } label: { Image(systemName: "chevron.right").font(.title2).padding() }
                .disabled(store.currentIndex >= store.items.count - 1)
        }
        .padding(.horizontal)
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                ForEach(PracticeFeature.PracticeMode.allCases, id: \.self) { mode in
                    Button { _ = store.send(.changePracticeMode(mode)) } label: { Label(mode.rawValue, systemImage: mode.icon) }
                }
            } label: {
                HStack {
                    Image(systemName: store.practiceMode.icon)
                    Text(store.practiceMode.rawValue).font(.caption)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { _ = store.send(.shuffleCards) } label: { Image(systemName: "shuffle") }
        }
    }
}

struct PracticeProgressHeader: View {
    let current: Int
    let total: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Card \(current) of \(total)").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%").font(.subheadline.bold()).foregroundStyle(Color.accentColor)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.2)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct PracticeFlashcard: View {
    let item: StudyItemState
    let isFlipped: Bool
    let dragOffset: CGFloat
    let rotation: Double
    
    var body: some View {
        ZStack {
            backOfCard.opacity(isFlipped ? 1 : 0).rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            frontOfCard.opacity(isFlipped ? 0 : 1).rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .offset(x: dragOffset)
        .rotationEffect(.degrees(rotation))
        .animation(.spring(), value: isFlipped)
    }
    
    private var backOfCard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.title).font(.subheadline).foregroundStyle(.secondary)
                Divider()
                Text(item.content).font(.title3)
                if !item.allImages.isEmpty {
                    Divider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(item.allImages.enumerated()), id: \.offset) { _, imageData in
                                if let uiImage = PlatformImage(data: imageData) {
                                    #if os(iOS)
                                    Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill).frame(width: 200, height: 150).clipShape(RoundedRectangle(cornerRadius: 8))
                                    #else
                                    Image(nsImage: uiImage).resizable().aspectRatio(contentMode: .fill).frame(width: 200, height: 150).clipShape(RoundedRectangle(cornerRadius: 8))
                                    #endif
                                }
                            }
                        }
                    }
                }
                if item.pdfData != nil {
                    Divider()
                    HStack {
                        Image(systemName: "doc.fill").foregroundStyle(.red)
                        Text("PDF Document Attached").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding().frame(maxWidth: .infinity).background(Color.red.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if !item.tags.isEmpty {
                    Divider()
                    FlowLayout(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag).font(.caption).padding(.horizontal, 10).padding(.vertical, 4).background(Color.purple.opacity(0.15)).foregroundStyle(.purple).clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(color: .green.opacity(0.2), radius: 10))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.5), lineWidth: 2))
    }
    
    private var frontOfCard: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "questionmark.circle.fill").font(.system(size: 50)).foregroundStyle(.blue.opacity(0.3))
            Text(item.title).font(.title2.bold()).multilineTextAlignment(.center).padding(.horizontal)
            Text("What do you remember?").font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 20) {
                VStack { Text("\(item.reviewCount)").font(.headline); Text("Reviews").font(.caption).foregroundStyle(.secondary) }
                Divider().frame(height: 30)
                VStack { Text("\(item.interval)").font(.headline); Text("Day Interval").font(.caption).foregroundStyle(.secondary) }
                Divider().frame(height: 30)
                VStack { Text(String(format: "%.1f", item.easeFactor)).font(.headline); Text("Ease").font(.caption).foregroundStyle(.secondary) }
            }
            .padding().background(Color.secondary.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(color: .blue.opacity(0.2), radius: 10))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue.opacity(0.5), lineWidth: 2))
    }
}

struct EmptyPracticeView: View {
    let mode: PracticeFeature.PracticeMode
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray").font(.system(size: 60)).foregroundStyle(.secondary)
            Text("No Cards Available").font(.title2.bold())
            Text(emptyMessage).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }
    var emptyMessage: String {
        switch mode {
        case .all: return "Add some study items to start practicing."
        case .due: return "No cards are due for review. Great job!"
        case .random: return "Add some study items to practice with random cards."
        case .difficult: return "No difficult cards found. You're doing well!"
        }
    }
}

struct PracticeCompleteView: View {
    let onRestart: () -> Void
    @State private var showConfetti = false
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 120, height: 120).scaleEffect(showConfetti ? 1.0 : 0.5).animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
                Image(systemName: "checkmark").font(.system(size: 50, weight: .bold)).foregroundStyle(.white)
            }
            Text("Practice Complete!").font(.title.bold())
            Text("You've gone through all the cards in this session.").font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            VStack(spacing: 12) {
                Text("💡 Tip").font(.headline)
                Text("Regular practice helps reinforce memories. Come back tomorrow to keep your streak going!").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding().background(Color.blue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal)
            Spacer()
            Button(action: onRestart) {
                Label("Practice Again", systemImage: "arrow.counterclockwise").font(.headline).frame(maxWidth: .infinity).padding().background(Color.accentColor).foregroundColor(.white).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal).padding(.bottom)
        }
        .onAppear { showConfetti = true }
    }
}

#Preview { PracticeView(store: Store(initialState: PracticeFeature.State()) { PracticeFeature() }) }

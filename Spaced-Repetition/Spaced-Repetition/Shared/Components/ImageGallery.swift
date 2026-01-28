//
//  ImageGallery.swift
//  Spaced-Repetition
//
//  Gallery view for displaying multiple images with pagination
//

import SwiftUI

// MARK: - Image Gallery View
struct ImageGalleryView: View {
    let images: [Data]
    @State private var currentIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Image display
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Page indicator for multiple images
            if images.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.accentColor : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                
                Text("\(currentIndex + 1) of \(images.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Compact Image Gallery (for lists/cards)
struct CompactImageGallery: View {
    let images: [Data]
    let maxVisible: Int
    
    init(images: [Data], maxVisible: Int = 3) {
        self.images = images
        self.maxVisible = maxVisible
    }
    
    var body: some View {
        HStack(spacing: -15) {
            ForEach(Array(images.prefix(maxVisible).enumerated()), id: \.offset) { index, imageData in
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .zIndex(Double(maxVisible - index))
                }
            }
            
            // Show remaining count
            if images.count > maxVisible {
                Text("+\(images.count - maxVisible)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Full Screen Image Viewer
struct FullScreenImageViewer: View {
    let images: [Data]
    @Binding var isPresented: Bool
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    
    init(images: [Data], isPresented: Binding<Bool>, startIndex: Int = 0) {
        self.images = images
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: startIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = value
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            scale = 1.0
                                        }
                                    }
                            )
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never))
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                Spacer()
                
                // Page info
                if images.count > 1 {
                    Text("\(currentIndex + 1) / \(images.count)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview("Image Gallery") {
    // Preview with sample data
    VStack(spacing: 20) {
        Text("Gallery previews would appear here with actual image data")
            .foregroundStyle(.secondary)
    }
    .padding()
}
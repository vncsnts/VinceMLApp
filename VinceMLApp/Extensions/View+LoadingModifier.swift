//
//  View+LoadingModifier.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 8/13/25.
//

import SwiftUI

struct LoadingViewModifier: ViewModifier {
    let isLoading: Bool
    let message: String
    let showProgress: Bool
    let progress: Double?
    
    init(
        isLoading: Bool,
        message: String = "Loading...",
        showProgress: Bool = false,
        progress: Double? = nil
    ) {
        self.isLoading = isLoading
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isLoading ? 2 : 0)
                .disabled(isLoading)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if showProgress && progress != nil {
                        VStack(spacing: 12) {
                            ProgressView(value: progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 200)
                            
                            Text("\(Int((progress ?? 0) * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                    
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .shadow(radius: 10)
                )
                .padding(.horizontal, 40)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    /// Adds a loading overlay to any view
    /// - Parameters:
    ///   - isLoading: Boolean that controls when to show the loading view
    ///   - message: Custom message to display (default: "Loading...")
    ///   - showProgress: Whether to show a progress bar (default: false)
    ///   - progress: Progress value between 0.0 and 1.0 (only used when showProgress is true)
    func loadingView(
        isLoading: Bool,
        message: String = "Loading...",
        showProgress: Bool = false,
        progress: Double? = nil
    ) -> some View {
        modifier(LoadingViewModifier(
            isLoading: isLoading,
            message: message,
            showProgress: showProgress,
            progress: progress
        ))
    }
}

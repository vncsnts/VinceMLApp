//
//  StatisticCardView.swift
//
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import SwiftUI

/// A reusable card component for displaying statistical information
/// 
/// Provides consistent styling and layout for multiple statistics in a single card.
/// Automatically handles spacing, alignment, and responsive layout.
///
/// **Features:**
/// - Multiple statistics with flexible alignment
/// - Consistent background styling and padding
/// - Automatic layout with proper spacing
/// - Responsive to data updates
///
/// **Usage:**
/// ```swift
/// StatisticCardView(
///     viewModel: StatisticCardViewModel(
///         title: "Model Performance",
///         statistics: [
///             StatisticItem(value: "87.5%", label: "Accuracy", alignment: .leading),
///             StatisticItem(value: "1.2MB", label: "Size", alignment: .trailing)
///         ]
///     )
/// )
/// ```
struct StatisticCardView: View {
    @State private var viewModel: StatisticCardViewModel
    
    /// Initialize with a StatisticCardViewModel
    /// - Parameter viewModel: The view model managing the statistics data
    init(viewModel: StatisticCardViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Card title
            Text(viewModel.title)
                .font(.headline)
            
            // Statistics layout
            HStack {
                ForEach(Array(viewModel.statistics.enumerated()), id: \.offset) { index, statistic in
                    VStack(alignment: swiftUIAlignment(from: statistic.alignment)) {
                        // Statistic value
                        Text(statistic.value)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Statistic label
                        Text(statistic.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Add spacer between items (except after last item)
                    if index < viewModel.statistics.count - 1 {
                        Spacer()
                    }
                }
            }
        }
        .padding() // Internal card padding
        .background(Color.gray.opacity(0.1)) // Card background
        .cornerRadius(10) // Rounded corners
    }
    
    /// Convert custom HorizontalAlignment to SwiftUI's HorizontalAlignment
    /// - Parameter alignment: Custom alignment enum
    /// - Returns: SwiftUI HorizontalAlignment
    private func swiftUIAlignment(from alignment: HorizontalAlignment) -> SwiftUI.HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Using ViewModel injection for more complex cases
        StatisticCardView(
            viewModel: StatisticCardViewModel(
                title: "Model Performance",
                statistics: [
                    StatisticItem(value: "94.2%", label: "Accuracy", alignment: .leading),
                    StatisticItem(value: "2.1s", label: "Inference Time", alignment: .trailing)
                ]
            )
        )
    }
    .padding()
}

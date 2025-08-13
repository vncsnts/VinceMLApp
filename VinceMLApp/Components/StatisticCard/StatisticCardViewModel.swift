//
//  StatisticCardViewModel.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import Foundation

/// ViewModel for StatisticCard component that manages statistical data display
/// 
/// Use this component to display multiple related statistics in a consistent card format.
/// Example: Training progress, model performance metrics, data counts, etc.
///
/// **Usage:**
/// ```swift
/// let statsVM = StatisticCardViewModel(
///     title: "Training Statistics",
///     statistics: [
///         StatisticItem(value: "25", label: "Total Images"),
///         StatisticItem(value: "3", label: "Categories")
///     ]
/// )
/// ```
@MainActor
@Observable
class StatisticCardViewModel {
    /// The title displayed at the top of the card
    var title: String
    
    /// Array of statistics to display in the card
    var statistics: [StatisticItem]
    
    /// Initialize with title and initial statistics
    /// - Parameters:
    ///   - title: The card title (keep concise, 1-3 words)
    ///   - statistics: Array of statistics to display (optimal: 2-4 items)
    init(title: String, statistics: [StatisticItem]) {
        self.title = title
        self.statistics = statistics
    }
    
    /// Update the displayed statistics with new data
    /// Call this method when underlying data changes to refresh the display
    /// - Parameter newStatistics: New array of statistics to display
    func updateStatistics(_ newStatistics: [StatisticItem]) {
        statistics = newStatistics
    }
}

/// Represents a single statistic item within a StatisticCard
/// 
/// **Usage:**
/// ```swift
/// StatisticItem(value: "87.5%", label: "Accuracy", alignment: .center)
/// ```
struct StatisticItem {
    /// The value to display (e.g., "25", "87.5%", "1.2MB")
    let value: String
    
    /// The label describing what the value represents
    let label: String
    
    /// How to align this statistic within the card layout
    let alignment: HorizontalAlignment
    
    /// Create a new statistic item
    /// - Parameters:
    ///   - value: The statistic value (use consistent formatting)
    ///   - label: Descriptive label for the statistic
    ///   - alignment: Layout alignment (.leading by default)
    init(value: String, label: String, alignment: HorizontalAlignment = .leading) {
        self.value = value
        self.label = label
        self.alignment = alignment
    }
}

/// Horizontal alignment options for statistic items
enum HorizontalAlignment {
    /// Align to the left side
    case leading
    /// Center alignment
    case center
    /// Align to the right side
    case trailing
}

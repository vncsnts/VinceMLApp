//
//  CameraService.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import Foundation
import UIKit
import AVFoundation

// MARK: - Protocol Definition

/// Service protocol for camera permission and access management
///
/// Provides centralized handling of camera permissions required for
/// image capture functionality throughout the application.
protocol CameraServiceProtocol {
    /// Checks current camera permission status without requesting access
    /// - Returns: true if camera access is currently authorized, false otherwise
    func checkCameraPermission() async -> Bool
    
    /// Requests camera permission from the user if not already granted
    /// - Returns: true if permission granted (existing or newly requested), false if denied
    func requestCameraPermission() async -> Bool
}

// MARK: - Service Implementation

/// CameraService manages camera permissions and access for the application
///
/// This service provides a centralized interface for camera permission management,
/// handling the complexity of AVFoundation authorization states and user interactions.
///
/// **Permission States Handled:**
/// - `.authorized` - Camera access previously granted
/// - `.notDetermined` - User hasn't been asked for permission yet
/// - `.denied` - User explicitly denied camera access
/// - `.restricted` - Camera access restricted by device policy
///
/// **Usage Pattern:**
/// ```swift
/// let cameraService = CameraService()
/// 
/// // Check before attempting camera operations
/// if await cameraService.checkCameraPermission() {
///     // Safe to use camera
/// } else {
///     // Request permission first
///     let granted = await cameraService.requestCameraPermission()
///     if granted {
///         // Can now use camera
///     } else {
///         // Handle denied permission (show settings redirect)
///     }
/// }
/// ```
///
/// **Integration with UI:**
/// - Use `checkCameraPermission()` for initial state determination
/// - Use `requestCameraPermission()` when user initiates camera-requiring action
/// - Handle denied permissions by directing users to Settings app
class CameraService: CameraServiceProtocol, ObservableObject {
    
    /// Checks the current camera permission status
    ///
    /// Queries the current authorization status for video capture without
    /// triggering any permission dialogs or user interactions.
    ///
    /// - Returns: true if camera access is authorized, false for all other states
    func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .authorized
    }
    
    /// Requests camera permission with automatic handling of all authorization states
    ///
    /// Intelligently handles the camera permission flow based on current state:
    /// - Returns immediately if already authorized
    /// - Requests permission if not yet determined
    /// - Returns false for denied/restricted states
    ///
    /// **User Experience:**
    /// - First-time users see iOS permission dialog
    /// - Previously denied users need to manually enable in Settings
    /// - Restricted devices (corporate/parental controls) cannot grant access
    ///
    /// - Returns: true if permission is granted (immediately or after request), false otherwise
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Already have permission
            return true
        case .notDetermined:
            // First time requesting - show permission dialog
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            // User previously denied or device is restricted
            // These require manual intervention in Settings app
            return false
        @unknown default:
            // Handle future authorization states conservatively
            return false
        }
    }
}

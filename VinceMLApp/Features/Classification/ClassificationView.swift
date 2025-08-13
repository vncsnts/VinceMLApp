//
//  ClassificationView.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import SwiftUI
import AVFoundation

/// Main view for image classification functionality
/// Provides live camera feed with real-time classification results
/// Handles model availability, camera permissions, and live video streaming
struct ClassificationView: View {
    @State private var viewModel: ClassificationViewModel
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    /// Initializes the classification view with a view model
    /// - Parameter viewModel: The view model managing classification state
    init(viewModel: ClassificationViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !viewModel.isModelLoaded {
                    // No Model Available
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Model Available")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Please train a model first using the Training tab")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Refresh") {
                            viewModel.loadModel()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else if !viewModel.hasCameraPermission {
                    // Camera Permission Required
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Camera Permission Required")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Please allow camera access to classify images")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Grant Permission") {
                            viewModel.requestCameraPermission()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else {
                    ZStack {
                        // Live Camera Preview with Real-time Classification
                        LiveCameraWrapper(viewModel: viewModel)
                        
                        // Main Classification Interface - Live Video
                        VStack(spacing: 20) {
                            // Classification Result
                            VStack(spacing: 8) {
                                Text("Live Classification")
                                    .font(.headline)
                                
                                if !viewModel.classificationResult.isEmpty {
                                    Text(viewModel.classificationResult)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("Point camera at object to classify")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            
                            if viewModel.isClassifying {
                                ProgressView("Classifying...")
                                    .padding()
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Identify")
            .onAppear {
                viewModel.startLiveClassification()
            }
            .onDisappear {
                viewModel.stopLiveClassification()
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}

// MARK: - Live Camera Wrapper using Generic CameraView
/// Wraps the live camera container with lifecycle management
/// Handles automatic camera restart when returning to the view
struct LiveCameraWrapper: View {
    let viewModel: ClassificationViewModel
    @State private var containerView: CameraContainerView?
    
    var body: some View {
        LiveCameraContainer(viewModel: viewModel, containerView: $containerView)
            .onAppear {
                // Force restart camera when wrapper appears to handle view transitions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    containerView?.restartCamera()
                }
            }
            .onDisappear {
                // Ensure classification stops and camera is properly cleaned up
                viewModel.stopLiveClassification()
                containerView?.stopCamera()
            }
    }
}

/// UIViewRepresentable that manages the live camera view lifecycle
/// Handles camera view creation, callback management, and proper cleanup
struct LiveCameraContainer: UIViewRepresentable {
    let viewModel: ClassificationViewModel
    @Binding var containerView: CameraContainerView?
    
    func makeUIView(context: Context) -> CameraContainerView {
        let containerView = CameraContainerView()
        
        // Create camera view with callback for direct reference storage
        let cameraView = CameraView(mode: .live, delegate: context.coordinator) { cameraPreviewView in
            containerView.cameraPreviewView = cameraPreviewView
            
            // Ensure camera is properly initialized after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                cameraPreviewView.restartCameraIfNeeded()
            }
        }
        
        // Embed camera view in UIHostingController
        let hostingController = UIHostingController(rootView: cameraView)
        hostingController.view.backgroundColor = .clear
        
        containerView.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // Store hosting controller for cleanup
        containerView.hostingController = hostingController
        
        // Store reference in binding for parent access
        DispatchQueue.main.async {
            self.containerView = containerView
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: CameraContainerView, context: Context) {
        // Force restart camera if needed when view updates
        if let cameraPreviewView = uiView.cameraPreviewView {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                cameraPreviewView.restartCameraIfNeeded()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel)
    }
    
    /// Coordinator class that handles camera frame delegation and classification
    class Coordinator: NSObject, CameraViewDelegate {
        let viewModel: ClassificationViewModel
        
        init(viewModel: ClassificationViewModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        func didCaptureImage(_ image: UIImage) {
            // Not used in live mode
        }
        
        func didReceiveLiveFrame(_ image: UIImage) {
            Task {
                guard await viewModel.isLiveClassificationEnabled else { 
                    return 
                }
                await viewModel.classifyImageLive(image)
            }
        }
    }
}

// MARK: - Custom Container View for Proper Cleanup
/// Custom UIView that manages UIHostingController and camera references
/// Handles proper cleanup to prevent memory leaks and ensure camera lifecycle management
class CameraContainerView: UIView {
    var hostingController: UIHostingController<CameraView>?
    var cameraPreviewView: CameraPreviewView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        forceStopCamera()
        cleanupHostingController()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview != nil {
            // Find and store reference to camera preview view when added to hierarchy
            findCameraPreviewView()
        } else {
            // Clean up when removed from hierarchy
            forceStopCamera()
            cleanupHostingController()
        }
    }
    
    /// Recursively searches for CameraPreviewView in the view hierarchy
    private func findCameraPreviewView() {
        func findInView(_ view: UIView) -> CameraPreviewView? {
            if let cameraView = view as? CameraPreviewView {
                return cameraView
            }
            for subview in view.subviews {
                if let found = findInView(subview) {
                    return found
                }
            }
            return nil
        }
        
        if let hostingController = hostingController {
            cameraPreviewView = findInView(hostingController.view)
            
            // If not found immediately, try again after SwiftUI builds hierarchy
            if cameraPreviewView == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.cameraPreviewView = findInView(hostingController.view)
                }
            }
        }
    }
    
    /// Forces the camera to stop using multiple approaches for reliability
    private func forceStopCamera() {
        // Approach 1: Use stored reference (preferred)
        if let cameraView = cameraPreviewView {
            cameraView.forceStop()
        } else {
            // Approach 2: Search for camera view in hierarchy
            if let hostingController = hostingController {
                
                @discardableResult
                func findAndStopCamera(_ view: UIView) -> Bool {
                    if let cameraView = view as? CameraPreviewView {
                        cameraView.forceStop()
                        return true
                    }
                    for subview in view.subviews {
                        if findAndStopCamera(subview) {
                            return true
                        }
                    }
                    return false
                }
                
                findAndStopCamera(hostingController.view)
            }
        }
    }
    
    /// Cleans up the hosting controller and removes it from hierarchy
    private func cleanupHostingController() {
        if let hostingController = hostingController {
            hostingController.willMove(toParent: nil)
            hostingController.view.removeFromSuperview()
            hostingController.removeFromParent()
            self.hostingController = nil
        }
    }
    
    // MARK: - Public Interface
    
    /// Stops the camera from external callers
    func stopCamera() {
        forceStopCamera()
    }
    
    /// Restarts the camera if it's not currently running
    /// Uses both stored reference and fallback search methods
    func restartCamera() {
        if let cameraView = cameraPreviewView {
            cameraView.restartCameraIfNeeded()
        } else {
            // Fallback: search for camera view in hierarchy
            if let hostingController = hostingController {
                
                @discardableResult
                func findAndRestartCamera(_ view: UIView) -> Bool {
                    if let cameraView = view as? CameraPreviewView {
                        cameraView.restartCameraIfNeeded()
                        return true
                    }
                    for subview in view.subviews {
                        if findAndRestartCamera(subview) {
                            return true
                        }
                    }
                    return false
                }
                
                findAndRestartCamera(hostingController.view)
            }
        }
    }
}

//
//  CaptureImageFlowView.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 8/13/25.
//

import SwiftUI
import AVFoundation

/// A batch image capture flow view that allows users to capture multiple training images in sequence
///
/// This view replaces the single capture button with a dedicated flow for batch capturing.
/// Users can capture multiple images for the selected label without returning to the main training view.
/// All business logic is handled by CaptureImageFlowViewModel following MVVM architecture.
///
/// **Features:**
/// - Live camera preview for continuous capture
/// - Batch image capture with instant feedback
/// - Progress tracking and statistics
/// - Automatic save to training data
///
/// **Usage:**
/// ```swift
/// CaptureImageFlowView(
///     viewModel: CaptureImageFlowViewModel(
///         trainingViewModel: trainingViewModel,
///         selectedLabel: selectedLabel
///     ),
///     onDismiss: { /* handle dismiss */ }
/// )
/// ```
struct CaptureImageFlowView: View {
    @State private var viewModel: CaptureImageFlowViewModel
    let onDismiss: () -> Void
    
    @State private var cameraView: BatchCameraPreviewView?
    
    init(viewModel: CaptureImageFlowViewModel, onDismiss: @escaping () -> Void) {
        self._viewModel = State(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Live camera view
                liveCameraSection
                VStack {
                    // Header with stats
                    headerSection
                    
                    Spacer()
                    
                    // Controls section
                    controlsSection
                }
            }
            .navigationTitle("Batch Capture")
            .navigationBarTitleDisplayMode(.inline)
            .loadingState(viewModel.loadingState, 
                         onRetry: { 
                             viewModel.saveAllCapturedImages() 
                         },
                         onDismiss: { 
                             viewModel.clearLoadingState() 
                         })
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Current label display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capturing for:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.selectedLabel.isEmpty ? "No label selected" : viewModel.selectedLabel)
                        .font(.headline)
                        .foregroundColor(viewModel.selectedLabel.isEmpty ? .red : .primary)
                }
                
                Spacer()
                
                // Recent captures thumbnail strip
                recentCapturesSection
            }
            
            // Session statistics
            HStack {
                StatItem(value: "\(viewModel.sessionStats.totalCaptured)", label: "Captured")
                
                Divider()
                    .frame(height: 30)
                
                StatItem(value: "\(viewModel.sessionStats.savedCount)", label: "Saved")
                
                Divider()
                    .frame(height: 30)
                
                StatItem(value: "\(viewModel.capturedImages.count)", label: "Pending")
            }
        }
        .padding()
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
    
    // MARK: - Live Camera Section
    private var liveCameraSection: some View {
        ZStack {
            // Camera view
            BatchCaptureCameraView(onImageCaptured: viewModel.handleImageCaptured, cameraView: $cameraView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            
            // Overlay UI
            VStack {
                Spacer()
                
                // Capture indicator
                if viewModel.isCapturing {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Capturing...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Primary capture button
            Button(action: {
                if let cameraView = cameraView {
                    cameraView.capturePhoto()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.canCapture ? Color.white : Color.gray)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(viewModel.canCapture ? Color.blue : Color.gray, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    if viewModel.isCapturing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                }
            }
            .disabled(!viewModel.canCapture)
            .scaleEffect(viewModel.isCapturing ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isCapturing)
            
            // Quick actions
            HStack(spacing: 20) {
                // Clear pending button
                Button(action: {
                    viewModel.clearPendingImages()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.title2)
                        Text("Clear")
                            .font(.caption)
                    }
                }
                .disabled(!viewModel.hasPendingImages)
                .foregroundColor(viewModel.hasPendingImages ? .red : .gray)
                
                Spacer()
                
                // Auto-capture toggle would go here if needed
                
                Spacer()
                
                // Save batch button
                Button(action: {
                    viewModel.saveAllCapturedImages()
                }) {
                    VStack(spacing: 4) {
                        if viewModel.loadingState.isSilentLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                        }
                        Text("Save All")
                            .font(.caption)
                    }
                }
                .disabled(!viewModel.canSaveAll)
                .foregroundColor(viewModel.canSaveAll ? .green : .gray)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Recent Captures Section
    private var recentCapturesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.capturedImages.enumerated()), id: \.offset) { index, image in
                        ImageGridItem(
                            imageProvider: .uiImage(image),
                            showDate: false,
                            size: CGSize(width: 50, height: 50),
                            onDelete: { viewModel.removeImage(at: index) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.capturedImages.count)
    }
}

// MARK: - Supporting Views
private struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Camera View for Batch Capture
private struct BatchCaptureCameraView: UIViewRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Binding var cameraView: BatchCameraPreviewView?
    
    func makeUIView(context: Context) -> BatchCameraPreviewView {
        let view = BatchCameraPreviewView()
        view.delegate = context.coordinator
        DispatchQueue.main.async {
            self.cameraView = view
        }
        return view
    }
    
    func updateUIView(_ uiView: BatchCameraPreviewView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, BatchCameraDelegate {
        let parent: BatchCaptureCameraView
        
        init(_ parent: BatchCaptureCameraView) {
            self.parent = parent
        }
        
        func didCaptureImage(_ image: UIImage) {
            parent.onImageCaptured(image)
        }
    }
}

// MARK: - Batch Camera Delegate
private protocol BatchCameraDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
}

// MARK: - Batch Camera Preview View
private class BatchCameraPreviewView: UIView {
    weak var delegate: BatchCameraDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            setupCamera()
        } else {
            stopCamera()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        // Use back camera
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ??
                              AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera) else { return }
        
        captureSession?.addInput(input)
        
        // Setup photo output
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput {
            captureSession?.addOutput(photoOutput)
        }
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = bounds
        
        layer.addSublayer(previewLayer!)
        
        // Add tap gesture for capture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(capturePhoto))
        addGestureRecognizer(tapGesture)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }
    }
    
    @objc func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings.photoQualityPrioritization = .balanced
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }
}

// MARK: - Photo Capture Delegate
extension BatchCameraPreviewView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            self.delegate?.didCaptureImage(image)
        }
    }
}

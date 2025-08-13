//
//  CameraView.swift
//  VinceMLApp
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - Camera Mode Enum
enum CameraMode {
    case capture    // Single image capture (for training) - uses native iOS camera
    case live       // Live video stream (for classification) - uses custom camera
}

// MARK: - Camera Delegate Protocol
protocol CameraViewDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
    func didReceiveLiveFrame(_ image: UIImage)
}

// MARK: - Native Camera View (for capture mode)
struct NativeCameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: NativeCameraView
        
        init(_ parent: NativeCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Generic Camera View
struct CameraView: View {
    let mode: CameraMode
    weak var delegate: CameraViewDelegate?
    @Binding var image: UIImage?
    let onCameraViewCreated: ((CameraPreviewView) -> Void)?
    
    // For capture mode
    init(mode: CameraMode = .capture, image: Binding<UIImage?>) {
        self.mode = mode
        self._image = image
        self.delegate = nil
        self.onCameraViewCreated = nil
    }
    
    // For live mode
    init(mode: CameraMode = .live, delegate: CameraViewDelegate, onCameraViewCreated: ((CameraPreviewView) -> Void)? = nil) {
        self.mode = mode
        self.delegate = delegate
        self._image = .constant(nil)
        self.onCameraViewCreated = onCameraViewCreated
    }
    
    var body: some View {
        switch mode {
        case .capture:
            NativeCameraView(image: $image)
        case .live:
            LiveCameraView(delegate: delegate, onCameraViewCreated: onCameraViewCreated)
        }
    }
}

// MARK: - Live Camera View (for live mode)
struct LiveCameraView: UIViewRepresentable {
    weak var delegate: CameraViewDelegate?
    let onCameraViewCreated: ((CameraPreviewView) -> Void)?
    
    /// Initializes a live camera view for real-time video streaming
    /// - Parameters:
    ///   - delegate: The delegate to receive captured frames
    ///   - onCameraViewCreated: Optional callback when the camera preview view is created
    init(delegate: CameraViewDelegate?, onCameraViewCreated: ((CameraPreviewView) -> Void)? = nil) {
        self.delegate = delegate
        self.onCameraViewCreated = onCameraViewCreated
    }
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.delegate = context.coordinator
        
        // Notify container about camera view creation for lifecycle management
        onCameraViewCreated?(view)
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Update delegate if needed
        uiView.delegate = context.coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraPreviewDelegate {
        let parent: LiveCameraView
        
        init(_ parent: LiveCameraView) {
            self.parent = parent
            super.init()
        }
        
        func didCaptureFrame(_ image: UIImage) {
            parent.delegate?.didReceiveLiveFrame(image)
        }
    }
}

// MARK: - Camera Preview Delegate Protocol
protocol CameraPreviewDelegate: AnyObject {
    func didCaptureFrame(_ image: UIImage)
}

// MARK: - Camera Preview UIView (for live mode only)
/// A UIView that manages AVCaptureSession for live camera preview and frame capture
/// Handles camera lifecycle, session management, and frame delegation
class CameraPreviewView: UIView {
    weak var delegate: CameraPreviewDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    // MARK: - Lifecycle Management
    
    deinit {
        cleanupCamera()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
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
    
    override func removeFromSuperview() {
        stopCamera()
        super.removeFromSuperview()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            stopCamera()
        }
    }
    
    // MARK: - Camera Setup and Management
    
    /// Sets up the camera session with back camera and video output
    /// Automatically starts the capture session on a background queue
    private func setupCamera() {
        // If we already have a running session, don't create another one
        if let session = captureSession, session.isRunning {
            return
        }
        
        // Clean up any existing session first
        if captureSession != nil {
            stopCamera()
        }
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium
        
        // Configure back camera input
        let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ??
                        AVCaptureDevice.default(for: .video)
        
        guard let camera = backCamera,
              let input = try? AVCaptureDeviceInput(device: camera) else { 
            return 
        }
        
        captureSession?.addInput(input)
        
        // Setup video output for live classification
        setupVideoOutput()
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = bounds
        
        layer.addSublayer(previewLayer!)
        
        // Start capture session on background queue to avoid blocking UI
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }
    }
    
    /// Configures video output for frame capture and delegation
    private func setupVideoOutput() {
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
        if let videoOutput = videoOutput {
            captureSession?.addOutput(videoOutput)
        }
    }
    
    /// Stops the camera session and cleans up all resources
    /// Safe to call multiple times
    private func stopCamera() {
        guard captureSession != nil else { return }
        
        // Stop on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.captureSession?.stopRunning()
            
            DispatchQueue.main.async {
                // Clean up delegate to prevent retain cycles
                self.videoOutput?.setSampleBufferDelegate(nil, queue: nil)
                
                // Remove preview layer
                self.previewLayer?.removeFromSuperlayer()
                
                // Clear all references
                self.captureSession = nil
                self.previewLayer = nil
                self.videoOutput = nil
            }
        }
    }
    
    /// Internal cleanup method called from deinit
    private func cleanupCamera() {
        stopCamera()
    }
    
    // MARK: - Public Interface
    
    /// Forces the camera to stop immediately
    /// Used by external classes for cleanup
    func forceStop() {
        stopCamera()
    }
    
    /// Restarts the camera if it should be running but isn't
    /// Useful for recovering from unexpected camera state issues
    func restartCameraIfNeeded() {
        // Check if camera should be running but isn't
        let shouldBeRunning = superview != nil
        let isCurrentlyRunning = captureSession?.isRunning ?? false
        
        if shouldBeRunning && !isCurrentlyRunning {
            setupCamera()
        }
    }
}

// MARK: - Video Output Delegate
extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    /// Processes captured video frames and forwards them to the delegate
    /// - Parameters:
    ///   - output: The capture output object
    ///   - sampleBuffer: The sample buffer containing the video frame
    ///   - connection: The capture connection
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Early exit if camera session is not running
        guard captureSession != nil && captureSession?.isRunning == true else {
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Convert to UIImage for delegate
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        // Forward to delegate on main queue
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let delegate = self.delegate else { 
                return 
            }
            delegate.didCaptureFrame(uiImage)
        }
    }
}

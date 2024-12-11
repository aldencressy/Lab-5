import AVFoundation
import Vision
import SwiftUI

class LivePoseFeedbackViewModel: NSObject, ObservableObject {
    // Published properties
    @Published var feedbackMessage: String = "Initializing camera..."
    @Published var isCameraAuthorized = false
    @Published var selectedPose: String = ""
    @Published var poseConfidence: CGFloat = 0.0
    @Published var isCorrectPose: Bool = false
    
    // Vision request
    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    
    // Capture session
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // Detection service
    private let detectionService = PoseDetectionService.shared
    
    private var lastRequestTime: Date = Date()
    private let requestInterval: TimeInterval = 3.0  // 3 seconds
    
    
    // Expected features matching the server's format
    private let expectedFeatures = [
        "right_shoulder_1_joint_x", "right_shoulder_1_joint_y", "right_shoulder_1_joint_confidence",
        "right_eye_joint_x", "right_eye_joint_y", "right_eye_joint_confidence",
        "left_upLeg_joint_x", "left_upLeg_joint_y", "left_upLeg_joint_confidence",
        "left_hand_joint_x", "left_hand_joint_y", "left_hand_joint_confidence",
        "root_x", "root_y", "root_confidence",
        "neck_1_joint_x", "neck_1_joint_y", "neck_1_joint_confidence",
        "head_joint_x", "head_joint_y", "head_joint_confidence",
        "left_shoulder_1_joint_x", "left_shoulder_1_joint_y", "left_shoulder_1_joint_confidence",
        "right_ear_joint_x", "right_ear_joint_y", "right_ear_joint_confidence",
        "left_leg_joint_x", "left_leg_joint_y", "left_leg_joint_confidence",
        "left_eye_joint_x", "left_eye_joint_y", "left_eye_joint_confidence",
        "left_foot_joint_x", "left_foot_joint_y", "left_foot_joint_confidence",
        "right_upLeg_joint_x", "right_upLeg_joint_y", "right_upLeg_joint_confidence",
        "right_leg_joint_x", "right_leg_joint_y", "right_leg_joint_confidence",
        "right_forearm_joint_x", "right_forearm_joint_y", "right_forearm_joint_confidence",
        "right_foot_joint_x", "right_foot_joint_y", "right_foot_joint_confidence",
        "right_hand_joint_x", "right_hand_joint_y", "right_hand_joint_confidence",
        "left_forearm_joint_x", "left_forearm_joint_y", "left_forearm_joint_confidence",
        "left_ear_joint_x", "left_ear_joint_y", "left_ear_joint_confidence"
    ]
    
    override init() {
        super.init()
        checkCameraAuthorization()
    }
    
    func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            isCameraAuthorized = false
        }
    }
    
    private func setupCamera() {
        guard isCameraAuthorized else { return }
        
        captureSession.beginConfiguration()
        
        // Add camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Add video output
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoProcessingQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Set video orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }
        
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func stopCamera() {
        captureSession.stopRunning()
    }
    
    private func processLandmarkKey(_ key: String) -> String {
        // First remove any existing "joint" suffix to avoid duplicates
        let cleanKey = key.replacingOccurrences(of: "_joint", with: "")
        
        switch cleanKey {
        case "right_shoulder": return "right_shoulder_1"
        case "left_shoulder": return "left_shoulder_1"
        case "right_elbow": return "right_forearm"
        case "left_elbow": return "left_forearm"
        case "right_wrist": return "right_hand"
        case "left_wrist": return "left_hand"
        case "right_hip": return "right_upLeg"
        case "left_hip": return "left_upLeg"
        case "right_knee": return "right_leg"
        case "left_knee": return "left_leg"
        case "right_ankle": return "right_foot"
        case "left_ankle": return "left_foot"
        case "neck": return "neck_1"
        case "root": return "root"      // don't add _joint
        case "nose": return "head"
        default: return cleanKey
        }
    }
    
    
}

extension LivePoseFeedbackViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              !selectedPose.isEmpty else { return }
        
        // Check if enough time has passed since the last request
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastRequestTime) >= requestInterval else {
            return
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([bodyPoseRequest])
            
            guard let observation = bodyPoseRequest.results?.first else {
                DispatchQueue.main.async {
                    self.feedbackMessage = "No pose detected"
                }
                return
            }
            
            // Extract landmarks
            let landmarks = try observation.recognizedPoints(.all)
            var features: [String: Double] = [:]
            
            // Process each landmark point
            for (key, point) in landmarks {
                let baseKey = processLandmarkKey(key.rawValue.rawValue)
                
                // Add _joint suffix for non-root points and add coordinates
                let finalKey = baseKey == "root" ? baseKey : baseKey + "_joint"
                
                // Add coordinates and confidence
                features["\(finalKey)_x"] = Double(point.location.x)
                features["\(finalKey)_y"] = Double(point.location.y)
                features["\(finalKey)_confidence"] = Double(point.confidence)
            }
            
            // Create the request body matching server's expected format exactly
            let requestBody = [
                "attempted_pose": selectedPose.lowercased(),
                "features": features
            ] as [String: Any]
            
            // Update last request time
            lastRequestTime = currentTime
            
            // Debug print
            print("\nSending to server:")
            print(requestBody)
            
            // Verify pose
            Task {
                do {
                    let isCorrect = try await detectionService.verifyPose(
                        requestBody: requestBody
                    )
                    
                    DispatchQueue.main.async { [self] in
                        self.isCorrectPose = isCorrect
                        self.feedbackMessage = isCorrect ?
                            "Great! Keep holding the pose!" :
                            "Adjust your pose to match the correct form"
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.feedbackMessage = "Error verifying pose: \(error.localizedDescription)"
                    }
                }
            }
            
        } catch {
            DispatchQueue.main.async {
                self.feedbackMessage = "Error processing frame: \(error.localizedDescription)"
            }
        }
    }
}

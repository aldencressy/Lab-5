import Foundation
import AVFoundation
import Vision

class LivePoseFeedbackViewModel: NSObject, ObservableObject {
    @Published var feedbackMessage: String = "Getting started..."
    @Published var isPoseCorrect: Bool = false

    private var selectedPose: String = "Tree"
    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "PoseDetectionQueue")

    override init() {
        super.init()
        setupSession()
    }

    func startSession() {
        captureSession.startRunning()
    }

    func stopSession() {
        captureSession.stopRunning()
    }

    func updateSelectedPose(_ pose: String) {
        selectedPose = pose
        feedbackMessage = "Perform the \(selectedPose) pose"
    }

    private func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            feedbackMessage = "Unable to access camera"
            return
        }

        captureSession.beginConfiguration()

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()
    }

    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([bodyPoseRequest])

            if let results = bodyPoseRequest.results,
               let observation = results.first,
               let points = try? observation.recognizedPoints(.all) {
                evaluatePose(points: points)
            }
        } catch {
            DispatchQueue.main.async {
                self.feedbackMessage = "Error processing frame: \(error.localizedDescription)"
            }
        }
    }

    private func evaluatePose(points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        // Evaluate the pose and update feedbackMessage
        DispatchQueue.main.async {
            // Example: Dummy logic for demonstration purposes
            if self.selectedPose == "Tree", points[.leftFoot]?.confidence ?? 0 > 0.5 {
                self.isPoseCorrect = true
                self.feedbackMessage = "Great job! You're doing the \(self.selectedPose) pose correctly!"
            } else {
                self.isPoseCorrect = false
                self.feedbackMessage = "Adjust your position for the \(self.selectedPose) pose."
            }
        }
    }
}

extension LivePoseFeedbackViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processFrame(sampleBuffer)
    }
}
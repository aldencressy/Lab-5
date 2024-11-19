import Foundation
import Vision
import UIKit

class PoseDetectionViewModel: ObservableObject {
    private var bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    @Published var recognizedPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var statusMessage: String = "Ready to collect data"

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func processImage(_ image: UIImage) {
        // Resize the image for consistent processing
        guard let resizedImage = resizeImage(image, targetSize: CGSize(width: 300, height: 300)),
              let cgImage = resizedImage.cgImage else {
            statusMessage = "Failed to resize or process the image."
            return
        }

        // Prepare Vision request handler
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            // Perform pose detection
            try handler.perform([bodyPoseRequest])
            
            if let results = bodyPoseRequest.results as? [VNHumanBodyPoseObservation], !results.isEmpty {
                extractBodyLandmarks(from: results)
            } else {
                DispatchQueue.main.async {
                    self.statusMessage = "No pose detected. Please try again."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "Error processing image: \(error.localizedDescription)"
            }
        }
    }

    private func extractBodyLandmarks(from observations: [VNHumanBodyPoseObservation]) {
        guard let observation = observations.first else { return }
        
        if let points = try? observation.recognizedPoints(.all) {
            DispatchQueue.main.async {
                self.recognizedPoints = points.mapValues { CGPoint(x: $0.x, y: $0.y) }
                self.statusMessage = "Pose detected with \(points.count) key points."
                
                // Log detected landmarks
                self.logLandmarks(points)
            }
        }
    }
    
    private func logLandmarks(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        print("Detected Landmarks:")
        for (jointName, point) in points {
            let confidence = point.confidence
            print("\(jointName.rawValue): \(point.location), Confidence: \(confidence)")
        }
    }
}

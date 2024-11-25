import Foundation
import Vision
import UIKit

class PoseDetectionViewModel: ObservableObject {
    private var bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    @Published var recognizedPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var statusMessage: String = "Ready to collect data"
    @Published var prediction: String? // To store the prediction result

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
                
                // Send the landmarks to the backend for prediction
                self.sendLandmarksForPrediction(points: points)
            }
        }
    }
    private func sendLandmarksForPrediction(points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        // Map the keys to the correct format expected by the backend
        let normalizedPoints = points.reduce(into: [String: Any]()) { dict, pair in
            // Extract the raw value from VNRecognizedPointKey
            let jointName = pair.key.rawValue
            dict["\(jointName)_x"] = pair.value.x
            dict["\(jointName)_y"] = pair.value.y
            dict["\(jointName)_confidence"] = pair.value.confidence
        }

        guard let url = URL(string: "http://10.9.145.21:8000/predict") else {
            print("Invalid URL for prediction endpoint")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "features": [normalizedPoints] // Send as an array of feature objects
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Failed to serialize JSON body: \(error.localizedDescription)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error making prediction request: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.statusMessage = "Prediction failed. Try again."
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.statusMessage = "No response from server."
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let predictions = json["predictions"] as? [String],
                   let firstPrediction = predictions.first {
                    DispatchQueue.main.async {
                        self.prediction = firstPrediction
                        self.statusMessage = "Prediction: \(firstPrediction)"
                    }
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Unexpected response from server."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to parse prediction response."
                }
            }
        }

        task.resume()
    }
    func resetPrediction() {
        recognizedPoints = [:]
        prediction = nil
        statusMessage = "Ready to collect data"
    }
}

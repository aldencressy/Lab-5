//
//  PoseDetectionViewModel.swift
//  Lab-5
//
//  Created by Alden Cressy on 11/18/24.
//


import Foundation
import Vision
import UIKit

class PoseDetectionViewModel: ObservableObject {
    private var bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    
    func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([bodyPoseRequest])
            if let results = bodyPoseRequest.results as? [VNHumanBodyPoseObservation] {
                self.extractBodyLandmarks(from: results)
            }
        } catch {
            print("Error processing image: \(error)")
        }
    }

    private func extractBodyLandmarks(from observations: [VNHumanBodyPoseObservation]) {
        for observation in observations {
            if let recognizedPoints = try? observation.recognizedPoints(.all) {
                print("Recognized Points: \(recognizedPoints)")
            }
        }
    }
}

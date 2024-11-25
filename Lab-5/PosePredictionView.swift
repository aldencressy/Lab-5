//
//  PosePredictionView.swift
//  Lab-5
//
//  Created by Alden Cressy on 11/24/24.
//


import SwiftUI
import Vision

struct PosePredictionView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var isPhotoPickerPresented = false
    @State private var predictedPose: String? = nil
    @State private var statusMessage: String = "Upload an image to predict the pose."
    @State private var selectedModel = "Random Forest" // Default selection
    @State private var accuracyRF: Double? = nil
    @State private var accuracyKNN: Double? = nil

    @State private var showQuestion = false // Controls whether the question is displayed
    @State private var isLoading = false   // Loading state during API request

    var onDismiss: (() -> Void)?

    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .border(Color.gray, width: 1)
                    .padding()
            } else {
                Text("No Image Selected")
                    .frame(height: 200)
                    .border(Color.gray, width: 1)
                    .padding()
            }

            HStack {
                Button("Select Image") {
                    isPhotoPickerPresented = true
                }
                .padding()

                Button("Predict") {
                    if let image = capturedImage {
                        predictPose(image: image)
                    } else {
                        statusMessage = "Please select an image before predicting."
                    }
                }
                .padding()
            }
            
            Picker("Pick Model", selection: $selectedModel) {
                Text("Random Forest").tag("Random Forest")
                Text("KNN").tag("KNN")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedModel) { newValue in
                saveSelectedModel(newValue)
            }
                        
            Text("Selected Model: \(selectedModel)")
                .padding()
            
            

            if let pose = predictedPose {
                Text("Predicted Pose: \(pose)")
                    .font(.title)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(8)
                    .onAppear {
                        showQuestion = true
                    }
            }
        
            // Display the question and buttons after the predicted pose
            if showQuestion {
                VStack {
                    Text("Was this prediction correct?")
                        .font(.headline)
                        .padding()
                    HStack {
                        Button(action: {
                            validatePrediction(correct: true)
                        }) {
                            Text("Yes")
                                .font(.title3)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                                    
                        Button(action: {
                            validatePrediction(correct: false)
                        }) {
                            Text("No")
                                .font(.title3)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                    .padding()
                } else if isLoading {
                    ProgressView("Submitting your response...")
                } else if !showQuestion && !isLoading && predictedPose != nil {
                    Text("Thank you for your feedback!")
                        .font(.title2)
                        .padding()
                }

            Text(statusMessage)
                .padding()
                .foregroundColor(.gray)

            Spacer()
            
            if let accuracyRF = accuracyRF {
                Text("Current Random Forest Accuracy: \(String(format: "%.2f", accuracyRF))%")
                    .font(.headline)
                    .padding()
            }
            if let accuracyKNN = accuracyKNN {
                Text("Current KNN Accuracy: \(String(format: "%.2f", accuracyKNN))%")
                    .font(.headline)
                    .padding()
            }

            Button("Done") {
                onDismiss?()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .sheet(isPresented: $isPhotoPickerPresented) {
            PhotoLibraryView(capturedImage: $capturedImage, isPresented: $isPhotoPickerPresented)
        }
    }
    
    func saveSelectedModel(_ model: String) {
        UserDefaults.standard.set(model, forKey: "SelectedModel")
    }

    func predictPose(image: UIImage) {
        var url: URL?
        
        if selectedModel == "KNN" {
            guard let knnUrl = URL(string: "http://10.9.141.79:8000/predictKNN") else {
                statusMessage = "Invalid server URL."
                return
            }
            url = knnUrl
        }else if selectedModel == "Random Forest" {
            guard let rfUrl = URL(string: "http://10.9.141.79:8000/predictRF") else {
                statusMessage = "Invalid server URL."
                return
            }
            url = rfUrl
        }
        
        guard let finalUrl = url else {
            statusMessage = "URL could not be determined."
            return
        }
    

        // Here, you should extract features from the image using Vision (like in LandmarkView)
        let extractedFeatures = extractFeatures(from: image)
        guard !extractedFeatures.isEmpty else {
            statusMessage = "Failed to extract features from the image."
            return
        }

        var request = URLRequest(url: finalUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["features": extractedFeatures]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    statusMessage = "Prediction failed: \(error.localizedDescription)"
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let predictions = json["predictions"] as? [String],
               let firstPrediction = predictions.first {
                DispatchQueue.main.async {
                    predictedPose = firstPrediction
                    statusMessage = "Prediction successful!"
                }
            } else {
                DispatchQueue.main.async {
                    statusMessage = "Failed to get prediction from the server."
                }
            }
        }
        task.resume()
    }
    
    private func validatePrediction(correct: Bool) {
        // Hide the question and show loading state
        showQuestion = false
        isLoading = true
        
        var url: URL?
        
        if selectedModel == "KNN" {
            guard let knnUrl = URL(string: "http://10.9.141.79:8000/validate_knn") else {
                statusMessage = "Invalid server URL."
                return
            }
            url = knnUrl
        }else if selectedModel == "Random Forest" {
            guard let rfUrl = URL(string: "http://10.9.141.79:8000/validate_rf") else {
                statusMessage = "Invalid server URL."
                return
            }
            url = rfUrl
        }
        
        guard let finalUrl = url else {
            statusMessage = "URL could not be determined."
            return
        }
            
            
        var request = URLRequest(url: finalUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
        let body: [String: Any] = ["correct": correct]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            
        URLSession.shared.dataTask(with: request) { data, response, error in
    
            DispatchQueue.main.async {
                isLoading = false
                    
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    print("Validation submitted successfully")
                } else {
                    print("Unexpected server response")
                }
                
                if let data = data {
                    
                    print("reached")
                    print(self.selectedModel)
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            // save accuracy
                            if selectedModel == "KNN" {
                                if let accuracy = jsonResponse["accuracy"] as? Double {
                                    self.accuracyKNN = accuracy // Save accuracy to use elsewhere
                                    print("Updated KNN Accuracy: \(accuracy)%")
                                }
                            }else if selectedModel == "Random Forest" {
                                if let accuracy = jsonResponse["accuracy"] as? Double {
                                    self.accuracyRF = accuracy
                                    print("Updated RF Accuracy: \(accuracy)%")
                                }
                            }
                        }
                    } catch {
                        print("Failed to parse JSON response: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
    }
    
    private func showAccuracyMessage(accuracy: Double) {
        print("Accuracy updated: \(accuracy)%")
        // Optionally update the UI to display the accuracy (e.g., use a state variable)
    }

    func extractFeatures(from image: UIImage) -> [String: Any] {
        var features: [String: Any] = [:]
        guard let cgImage = image.cgImage else { return features }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNDetectHumanBodyPoseRequest { request, _ in
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else { return }

            if let points = try? observation.recognizedPoints(.all) {
                for (key, point) in points {
                    features["\(key.rawValue)_x"] = point.x
                    features["\(key.rawValue)_y"] = point.y
                    features["\(key.rawValue)_confidence"] = point.confidence
                }
            }
        }

        do {
            try handler.perform([request])
        } catch {
            print("Error performing Vision request: \(error)")
        }

        // Ensure all expected keys exist in the feature dictionary
        let expectedKeys = [
            "right_shoulder_1_joint_x", "right_shoulder_1_joint_y", "right_shoulder_1_joint_confidence",
            "right_eye_joint_x", "right_eye_joint_y", "right_eye_joint_confidence",
            // Add all other expected keys here
        ]

        for key in expectedKeys {
            if features[key] == nil {
                features[key] = 0.0 // Default to 0 if missing
            }
        }

        return features
    }
}

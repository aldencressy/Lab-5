import SwiftUI
import Vision

struct ImageLabelingView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var isPhotoPickerPresented = false
    @State private var selectedPose: String = "downdog" // Default pose
    @State private var statusMessage: String = "Select an image and label it."
    @State private var detectedFeatures: [String: Any] = [:] // Store detected features

    let poses = ["downdog", "goddess", "plank", "tree", "warrior2"] // Dropdown options

    var onDismiss: (() -> Void)? // Callback for dismissal

    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .border(Color.gray, width: 1)
                    .padding()

                if !detectedFeatures.isEmpty {
                    Text("Features detected. Ready to upload.")
                        .font(.headline)
                        .padding()
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(8)
                }
            } else {
                Text("No Image Selected")
                    .frame(height: 200)
                    .border(Color.gray, width: 1)
                    .padding()
            }

            // Dropdown for selecting a pose
            Picker("Select Pose", selection: $selectedPose) {
                ForEach(poses, id: \.self) { pose in
                    Text(pose.capitalized).tag(pose)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            HStack {
                Button("Select Image") {
                    isPhotoPickerPresented = true
                }
                .padding()

                Button("Upload") {
                    if let image = capturedImage, !detectedFeatures.isEmpty {
                        uploadFeatures(label: selectedPose)
                    } else if detectedFeatures.isEmpty {
                        statusMessage = "Please detect features before uploading."
                    } else {
                        statusMessage = "Please select an image before uploading."
                    }
                }
                .padding()
            }

            Text(statusMessage)
                .padding()
                .foregroundColor(.gray)

            Spacer()

            Button("Done") {
                onDismiss?() // Notify parent when done
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .sheet(isPresented: $isPhotoPickerPresented, onDismiss: {
            if let image = capturedImage {
                detectFeatures(from: image)
            }
        }) {
            PhotoLibraryView(capturedImage: $capturedImage, isPresented: $isPhotoPickerPresented)
        }
    }

    /// Detect features using Vision and extract key points
    private func detectFeatures(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            statusMessage = "Failed to process image."
            return
        }

        let request = VNDetectHumanBodyPoseRequest { request, error in
            if let error = error {
                statusMessage = "Feature detection failed: \(error.localizedDescription)"
                return
            }

            guard let results = request.results as? [VNHumanBodyPoseObservation], let observation = results.first else {
                statusMessage = "No body pose detected."
                return
            }

            processObservation(observation)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            statusMessage = "Error performing request: \(error.localizedDescription)"
        }
    }

    /// Process the VNHumanBodyPoseObservation and prepare detected features
    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
        do {
            let points = try observation.recognizedPoints(.all)
            var features: [String: Any] = [:]

            for (key, point) in points {
                features["\(key.rawValue)_x"] = point.x
                features["\(key.rawValue)_y"] = point.y
                features["\(key.rawValue)_confidence"] = point.confidence
            }

            detectedFeatures = features
            statusMessage = "Feature detection complete. Ready to upload."
        } catch {
            statusMessage = "Error processing observation: \(error.localizedDescription)"
        }
    }

    /// Upload detected features to the backend
    private func uploadFeatures(label: String) {
        guard !detectedFeatures.isEmpty else {
            statusMessage = "No features detected for upload."
            return
        }

        guard let url = URL(string: "http://10.9.145.21:8000/upload") else {
            statusMessage = "Invalid server URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "features": detectedFeatures,
            "label": label,
            "dsid": 1 // Replace with the appropriate dataset ID
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            statusMessage = "Failed to encode features for upload."
            return
        }

        statusMessage = "Uploading features..."
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    statusMessage = "Upload failed: \(error.localizedDescription)"
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    statusMessage = "Features uploaded successfully."
                    detectedFeatures = [:] // Clear features after upload
                }
            } else {
                DispatchQueue.main.async {
                    statusMessage = "Failed to upload features. Try again."
                }
            }
        }
        task.resume()
    }
}

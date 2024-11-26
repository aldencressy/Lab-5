import SwiftUI
import CoreML
import Vision

struct LocalModelView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var predictedPose: String? = nil
    @State private var isPhotoPickerPresented = false
    @State private var model: VNCoreMLModel? = nil
    @State private var statusMessage: String = "Initializing..."
    @State private var isTraining: Bool = false

    var onDismiss: (() -> Void)

    var body: some View {
        VStack {
            Text("Local Trained Model")
                .font(.largeTitle)
                .padding()

            if isTraining {
                ProgressView("Training Model...")
                    .padding()
            } else {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .padding()
                } else {
                    Text("No Image Selected")
                        .frame(height: 300)
                        .background(Color.gray.opacity(0.2))
                        .padding()
                }

                Button("Select Image") {
                    isPhotoPickerPresented = true
                }
                .padding()

                Button("Classify Pose") {
                    if let image = capturedImage, let model = model {
                        classifyImage(image: image, with: model)
                    } else {
                        statusMessage = "No image or model available."
                    }
                }
                .padding()

                if let pose = predictedPose {
                    Text("Predicted Pose: \(pose)")
                        .font(.title)
                        .padding()
                }

                Text(statusMessage)
                    .padding()
                    .foregroundColor(.gray)

                Spacer()
            }

            Button("Done") {
                onDismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .sheet(isPresented: $isPhotoPickerPresented) {
            PhotoLibraryView(capturedImage: $capturedImage, isPresented: $isPhotoPickerPresented)
        }
        .onAppear {
            loadOrTrainModel()
        }
    }

    private func loadOrTrainModel() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelURL = documentsDirectory.appendingPathComponent("YogaPoseClassifier.mlmodel")

        if fileManager.fileExists(atPath: modelURL.path) {
            do {
                let compiledModelURL = try MLModel.compileModel(at: modelURL)
                model = try VNCoreMLModel(for: MLModel(contentsOf: compiledModelURL))
                statusMessage = "Model created and loaded."
            } catch {
                statusMessage = "Error creating and loading model: \(error.localizedDescription)"
            }
        } else {
            trainModel()
        }
    }

    private func trainModel() {
        isTraining = true
        statusMessage = "Training model..."

        // Get dataset from the server
        DatasetHandler.shared.fetchDataset { datasetURL in
            guard let datasetURL = datasetURL else {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to fetch dataset."
                    self.isTraining = false
                }
                return
            }

            // Train the model
            CreateMLTrainer.shared.trainModel(datasetURL: datasetURL) { modelURL in
                DispatchQueue.main.async {
                    if let modelURL = modelURL {
                        do {
                            let compiledModelURL = try MLModel.compileModel(at: modelURL)
                            self.model = try VNCoreMLModel(for: MLModel(contentsOf: compiledModelURL))
                            self.statusMessage = "Model trained and loaded successfully."
                        } catch {
                            self.statusMessage = "Error loading trained model: \(error.localizedDescription)"
                        }
                    } else {
                        self.statusMessage = "Model training failed."
                    }
                    self.isTraining = false
                }
            }
        }
    }

    private func classifyImage(image: UIImage, with model: VNCoreMLModel) {
        guard let ciImage = CIImage(image: image) else {
            statusMessage = "Failed to convert UIImage to CIImage."
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                statusMessage = "Classification failed: \(error.localizedDescription)"
                return
            }

            guard let results = request.results as? [VNClassificationObservation],
                  let firstResult = results.first else {
                statusMessage = "No classification results available."
                return
            }

            DispatchQueue.main.async {
                predictedPose = firstResult.identifier
                statusMessage = "Classification complete!"
            }
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            statusMessage = "Error performing classification: \(error.localizedDescription)"
        }
    }
}

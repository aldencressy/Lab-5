import CreateML
import Foundation
import ZIPFoundation

class CreateMLTrainer {
    static let shared = CreateMLTrainer()
    private init() {}

    func trainModel(datasetURL: URL, completion: @escaping (URL?) -> Void) {
        do {
            // Unzip the dataset
            let fileManager = FileManager.default
            let unzippedDirectory = datasetURL.deletingPathExtension()

            if fileManager.fileExists(atPath: unzippedDirectory.path) {
                try fileManager.removeItem(at: unzippedDirectory)
            }
            try fileManager.unzipItem(at: datasetURL, to: unzippedDirectory)

            // Get the training dataset
            let trainDirectory = unzippedDirectory.appendingPathComponent("Train")

            // Ensure that it's not empty
            let contents = try fileManager.contentsOfDirectory(atPath: trainDirectory.path)
            guard !contents.isEmpty else {
                print("Unzipped dataset is empty.")
                completion(nil)
                return
            }

            // Train the model
            let trainingData = try MLImageClassifier.DataSource.labeledDirectories(at: trainDirectory)
            let model = try MLImageClassifier(trainingData: trainingData)

            // Save the trained model
            let modelURL = unzippedDirectory.appendingPathComponent("YogaPoseClassifier.mlmodel")
            try model.write(to: modelURL)

            print("Model trained and saved to: \(modelURL.path)")
            completion(modelURL)
        } catch {
            print("Error during training: \(error.localizedDescription)")
            completion(nil)
        }
    }
}

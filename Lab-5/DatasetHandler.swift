import Foundation

class DatasetHandler {
    static let shared = DatasetHandler()
    private init() {}

    func fetchDataset(completion: @escaping (URL?) -> Void) {
        guard let url = URL(string: "http://192.168.1.226:8000/export_createml_dataset") else {
            print("Invalid Flask server URL.")
            completion(nil)
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let error = error {
                print("Error fetching dataset: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Get localURL for downloaded file
            guard let localURL = localURL else {
                print("Dataset not found in the response.")
                completion(nil)
                return
            }

            // Save the file
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let datasetDestination = documentsDirectory.appendingPathComponent("createml_ready.zip")

            do {
                // Remove old file if it exists
                if fileManager.fileExists(atPath: datasetDestination.path) {
                    try fileManager.removeItem(at: datasetDestination)
                }

                // Move the dataset
                try fileManager.moveItem(at: localURL, to: datasetDestination)
                print("Dataset saved to: \(datasetDestination.path)")
                completion(datasetDestination)
            } catch {
                print("Error saving dataset: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
}

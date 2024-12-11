import Foundation

class PoseDetectionService {
    static let shared = PoseDetectionService()
    private let baseURL = "http://10.9.150.102:8000"
    
    enum PoseDetectionError: Error {
        case invalidURL8997u8443
        case invalidResponse
        case networkError(Error)
        case decodingError
    }
    
    func verifyPose(requestBody: [String: Any]) async throws -> Bool {
        let url = URL(string: "\(baseURL)/predict")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Extract features and wrap them in an array as the server expects
        guard let features = requestBody["features"] as? [String: Double],
              let attemptedPose = requestBody["attempted_pose"] as? String else {
            throw PoseDetectionError.invalidResponse
        }
        
        // Create the request body as the server expects
        let serverRequestBody: [String: Any] = [
            "attempted_pose": attemptedPose,
            "features": [features]  // Wrap features dictionary in an array
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: serverRequestBody)
        request.httpBody = jsonData
        
        // Debug print the exact JSON being sent
        if let requestString = String(data: jsonData, encoding: .utf8) {
            print("\nRequest JSON being sent to server:")
            print(requestString)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug print response
        if let responseString = String(data: data, encoding: .utf8) {
            print("\nServer Response:")
            print(responseString)
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PoseDetectionError.invalidResponse
        }
        
        struct PredictionResponse: Codable {
            let attempted_pose: String
            let predicted_pose: String
            let is_correct: Bool
            let feedback: String
        }
        
        let result = try JSONDecoder().decode(PredictionResponse.self, from: data)
        print("\nDecoded response:", result)
        return result.is_correct
    }
}

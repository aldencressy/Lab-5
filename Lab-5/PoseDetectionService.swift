import Foundation

class PoseDetectionService {
    static let shared = PoseDetectionService()
    private let baseURL = "http://your-server-url:8000" // Replace with your server URL
    
    enum PoseDetectionError: Error {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case decodingError
    }
    
    func verifyPose(landmarks: [String: Any], pose: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/predictRF")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "features": landmarks,
            "attempted_pose": pose
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PoseDetectionError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(PredictionResponse.self, from: data)
        return result.predictions.first == pose
    }
    
    func sendValidationFeedback(correct: Bool) async throws {
        let url = URL(string: "\(baseURL)/validate_rf")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["correct": correct]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PoseDetectionError.invalidResponse
        }
    }
}
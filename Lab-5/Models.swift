import Foundation

struct PredictionResponse: Codable {
    let predictions: [String]
}

struct YogaPose: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let difficulty: Difficulty
    let instructions: [String]
    let mediaURL: URL
    let isVideo: Bool
    var isFavorite: Bool
    
    enum Difficulty: String, Codable {
        case beginner
        case intermediate
        case advanced
    }
}

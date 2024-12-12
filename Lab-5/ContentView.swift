import SwiftUI

struct ContentView: View {
    private let availablePoses: [YogaPose] = [
        YogaPose(
            id: UUID(),
            name: "downdog",  // Exact name as in ML model
            description: "A pose that stretches and strengthens the entire body",
            difficulty: .beginner,
            instructions: [
                "Start on hands and knees",
                "Lift your knees off the floor",
                "Straighten your legs and arms",
                "Push your heels toward the ground",
                "Keep your head between your arms"
            ],
            mediaURL: URL(string: "placeholder")!,
            isVideo: false,
            isFavorite: false
        ),
        YogaPose(
            id: UUID(),
            name: "goddess",  // Exact name as in ML model
            description: "A powerful standing pose that opens the hips",
            difficulty: .intermediate,
            instructions: [
                "Step feet wide apart",
                "Turn toes out 45 degrees",
                "Bend knees over ankles",
                "Raise arms to shoulder height",
                "Keep spine straight"
            ],
            mediaURL: URL(string: "placeholder")!,
            isVideo: false,
            isFavorite: false
        ),
        YogaPose(
            id: UUID(),
            name: "plank",  // Exact name as in ML model
            description: "A core strengthening pose that builds stability",
            difficulty: .beginner,
            instructions: [
                "Start in push-up position",
                "Keep body in straight line",
                "Engage core muscles",
                "Keep shoulders over wrists",
                "Look slightly forward"
            ],
            mediaURL: URL(string: "placeholder")!,
            isVideo: false,
            isFavorite: false
        ),
        YogaPose(
            id: UUID(),
            name: "tree",  // Exact name as in ML model
            description: "A balancing pose that improves focus and stability",
            difficulty: .beginner,
            instructions: [
                "Stand on one leg",
                "Place other foot on inner thigh or calf",
                "Never place foot on knee",
                "Bring hands to heart center",
                "Fix gaze on steady point"
            ],
            mediaURL: URL(string: "placeholder")!,
            isVideo: false,
            isFavorite: false
        ),
        YogaPose(
            id: UUID(),
            name: "warrior2",  // Exact name as in ML model
            description: "A standing pose that builds strength and stability",
            difficulty: .beginner,
            instructions: [
                "Step feet wide apart",
                "Turn front foot out 90 degrees",
                "Bend front knee over ankle",
                "Extend arms parallel to ground",
                "Gaze over front hand"
            ],
            mediaURL: URL(string: "placeholder")!,
            isVideo: false,
            isFavorite: false
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Welcome to Pose Trainer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                NavigationLink(
                    destination: PoseSelectionView(availablePoses: availablePoses)
                ) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .font(.title2)
                        Text("Practice")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                NavigationLink(
                    destination: PoseLearnView(availablePoses: availablePoses)
                ) {
                    HStack {
                        Image(systemName: "figure.mind.and.body")
                            .font(.title2)
                        Text("Learn")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct PoseSelectionView: View {
    let availablePoses: [YogaPose]
    
    private let poseImages: [String: String] = [
        "downdog": "downdog-preview",
        "goddess": "goddess-preview",
        "plank": "plank-preview",
        "tree": "tree-preview",
        "warrior2": "warrior2-preview"
    ]

    var body: some View {
        List(availablePoses) { pose in
            NavigationLink(
                destination: LivePoseFeedbackView(selectedPose: pose)
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if let imageName = poseImages[pose.name],
                       let uiImage = UIImage(named: imageName) ?? UIImage(contentsOfFile: Bundle.main.path(forResource: imageName, ofType: "jpg") ?? "") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        // Fallback if image loading fails
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .cornerRadius(8)
                            .overlay(
                                Text("Image not found: \(poseImages[pose.name] ?? "unknown")")
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(pose.name.capitalized)
                                .font(.headline)
                            Spacer()
                            Text(pose.difficulty.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(pose.difficulty == .beginner ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                )
                        }
                        
                        Text(pose.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Select Pose")
    }
}

struct PoseLearnView: View {
    let availablePoses: [YogaPose]

    var body: some View {
        List(availablePoses) { pose in
            NavigationLink(
                destination: LearnPosesView(selectedPose: pose)
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(pose.name.capitalized)
                            .font(.headline)
                        Spacer()
                        Text(pose.difficulty.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(pose.difficulty == .beginner ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            )
                    }
                    Text(pose.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 5)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Select Pose")
    }
}

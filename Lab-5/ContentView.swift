import SwiftUI

struct ContentView: View {
    @State private var isTrainViewPresented = false
    @State private var isPredictViewPresented = false
    @State private var isLocallyTrainedPresented = false
    @State private var isLiveFeedbackPresented = false
    @State private var selectedPose: YogaPose?
    
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
        VStack(spacing: 20) {
            Text("Pose Trainer and Predictor")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Live Feedback") {
                isLiveFeedbackPresented = true
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
            .sheet(isPresented: $isLiveFeedbackPresented) {
                NavigationView {
                    List(availablePoses) { pose in
                        Button(action: {
                            selectedPose = pose
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(pose.name.capitalized)
                                        .font(.headline)
                                    Spacer()
                                    if selectedPose?.id == pose.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Text(pose.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text(pose.difficulty.rawValue.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.blue.opacity(0.2))
                                    )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .navigationTitle("Select a Pose")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Start") {
                                if selectedPose != nil {
                                    isLiveFeedbackPresented = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        showLiveFeedback()
                                    }
                                }
                            }
                            .disabled(selectedPose == nil)
                        }
                        
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                isLiveFeedbackPresented = false
                                selectedPose = nil
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedPose) { pose in
                LivePoseFeedbackView(selectedPose: pose)
            }
        }
    }
    
    private func showLiveFeedback() {
        selectedPose = selectedPose
    }
}

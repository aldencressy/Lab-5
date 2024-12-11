import SwiftUI
import AVKit

struct LearnPosesView: View {
    let selectedPose: YogaPose
    @State private var player: AVPlayer?
    
    // Dictionary for pose details
    let poseDetails: [String: (text: String, video: String)] = [
        "tree": ("Tree Pose helps improve balance and stability.", "tree"),
        "downdog": ("Downward Dog stretches your back and strengthens your arms.", "downdog"),
        "mountain": ("Mountain Pose promotes good posture and stability.", "mountain"),
        "plank": ("Plank Pose builds core strength and stamina.", "plank"),
        "goddess": ("Goddess Pose strengthens your legs and opens your hips.", "goddess"),
        "warrior2": ("Warrior II builds strength and stability in the legs and core.", "warrior2")
    ]
    
    private func createPlayer(for poseName: String) -> AVPlayer? {
        guard let path = Bundle.main.path(forResource: poseName, ofType: "mp4") else {
            print("Could not find video file for \(poseName)")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        return AVPlayer(url: url)
    }
    
    var body: some View {
        if let details = poseDetails[selectedPose.name] {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Let's Learn \(selectedPose.name.capitalized)")
                        .font(.title)
                        .bold()
                    
                    Text(details.text)
                        .font(.body)
                    
                    // Video Player
                    if let player = createPlayer(for: details.video) {
                        VideoPlayer(player: player)
                            .frame(height: 220)
                            .cornerRadius(12)
                            .onAppear {
                                // Reset video to beginning
                                player.seek(to: .zero)
                                // Start playing
                                player.play()
                            }
                            .onDisappear {
                                // Stop playing when view disappears
                                player.pause()
                            }
                    } else {
                        Text("Video not available")
                            .foregroundColor(.red)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    
                    // Additional details from YogaPose
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Description:")
                            .font(.headline)
                        Text(selectedPose.description)
                            .font(.body)
                        
                        Text("Instructions:")
                            .font(.headline)
                        ForEach(selectedPose.instructions, id: \.self) { step in
                            Text("• \(step)")
                                .font(.body)
                        }
                    }
                }
                .padding()
            }
        } else {
            Text("Pose details not found.")
                .foregroundColor(.red)
        }
    }
}

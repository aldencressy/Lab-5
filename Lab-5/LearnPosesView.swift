import SwiftUI
import AVKit

struct LearnPosesView: View {
    let selectedPose: YogaPose
    @State private var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss
    
    // Dictionary for pose details
    let poseDetails: [String: (text: String, video: String)] = [
        "tree": ("Tree Pose helps improve balance and stability.", "tree"),
        "downdog": ("Downward Dog stretches your back and strengthens your arms.", "downdog"),
        "mountain": ("Mountain Pose promotes good posture and stability.", "mountain"),
        "plank": ("Plank Pose builds core strength and stamina.", "plank"),
        "goddess": ("Goddess Pose strengthens your legs and opens your hips.", "goddess"),
        "warrior2": ("Warrior II builds strength and stability in the legs and core.", "warrior2")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Let's Learn \(selectedPose.name.capitalized)")
                    .font(.title)
                    .bold()
                
                if let details = poseDetails[selectedPose.name.lowercased()] {
                    Text(details.text)
                        .font(.body)
                    
                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(height: 220)
                            .cornerRadius(12)
                    } else {
                        Text("Loading video...")
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
                
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
        .navigationTitle("Tutorial")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func setupVideo() {
        guard let details = poseDetails[selectedPose.name.lowercased()],
              let url = Bundle.main.url(forResource: details.video, withExtension: "mp4") else {
            return
        }
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        // Initialize player
        let newPlayer = AVPlayer(url: url)
        newPlayer.seek(to: .zero)
        self.player = newPlayer
    }
}

import SwiftUI
import AVKit

struct LearnPosesView: View {
    let selectedPose: YogaPose 

    // Dictionary for pose details
    let poseDetails: [String: (text: String, video: String)] = [
        "tree": ("Tree Pose helps improve balance and stability.", "tree_pose_video"),
        "downdog": ("Downward Dog stretches your back and strengthens your arms.", "downdog_pose_video"),
        "mountain": ("Mountain Pose promotes good posture and stability.", "mountain_pose_video"),
        "plank": ("Plank Pose builds core strength and stamina.", "plank_pose_video"),
        "goddess": ("Goddess Pose strengthens your legs and opens your hips.", "goddess_pose_video"),
        "warrior2": ("Warrior II builds strength and stability in the legs and core.", "warrior2_pose_video")
    ]

    var body: some View {
        if let details = poseDetails[selectedPose.name] { // Use the `name` property to access the dictionary
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Let's Learn \(selectedPose.name.capitalized)")
                        .font(.title)
                        .bold()

                    Text(details.text)
                        .font(.body)

                    // Placeholder for the video
                    Text("Watch Video: \(details.video)")
                        .font(.caption)
                        .foregroundColor(.blue)

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


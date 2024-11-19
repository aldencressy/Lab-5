import SwiftUI
import Vision

struct LandmarkView: View {
    let image: UIImage
    let points: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let onBack: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Display the image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        GeometryReader { imageGeometry in
                            let imageSize = calculateDisplayedImageSize(for: image, in: imageGeometry.size)
                            let xOffset = (imageGeometry.size.width - imageSize.width) / 2
                            let yOffset = (imageGeometry.size.height - imageSize.height) / 2

                            ZStack {
                                // Draw each point relative to the displayed image
                                ForEach(points.keys.sorted(by: { $0.rawValue.rawValue < $1.rawValue.rawValue }), id: \.self) { key in
                                    if let point = points[key] {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 10, height: 10)
                                            .position(
                                                x: xOffset + (point.x * imageSize.width),
                                                y: yOffset + ((1 - point.y) * imageSize.height) // Flip y-axis
                                            )
                                    }
                                }
                            }
                        }
                    )

                // Back button
                VStack {
                    HStack {
                        Button(action: onBack) {
                            Label("Back", systemImage: "arrow.left")
                                .padding()
                                .background(Color.gray.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }

    /// Calculate the size of the displayed image within the view
    private func calculateDisplayedImageSize(for image: UIImage, in containerSize: CGSize) -> CGSize {
        let imageAspectRatio = image.size.width / image.size.height
        let containerAspectRatio = containerSize.width / containerSize.height

        if imageAspectRatio > containerAspectRatio {
            // Image is wider than the container
            let width = containerSize.width
            let height = width / imageAspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Image is taller than the container
            let height = containerSize.height
            let width = height * imageAspectRatio
            return CGSize(width: width, height: height)
        }
    }
}

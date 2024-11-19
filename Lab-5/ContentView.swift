import SwiftUI

struct ContentView: View {
    @State private var statusMessage = "Press Start to Collect Data"
    @StateObject private var viewModel = PoseDetectionViewModel()

    @State private var isCameraPresented = false
    @State private var capturedImage: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            Text(statusMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                isCameraPresented = true
            }) {
                Text("Open Camera")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                
                Button(action: {
                    viewModel.processImage(image)
                    statusMessage = "Pose data processed!"
                }) {
                    Text("Analyze Image")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .sheet(isPresented: $isCameraPresented) {
            CameraView(capturedImage: $capturedImage, isPresented: $isCameraPresented)
        }
    }
}

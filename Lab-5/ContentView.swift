import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PoseDetectionViewModel()
    @State private var isCameraPresented = false
    @State private var isPhotoLibraryPresented = false
    @State private var capturedImage: UIImage?
    @State private var showLandmarkView = false

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.statusMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()

            // Button to open the camera
            Button("Open Camera") {
                isCameraPresented = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            // Button to open the photo library
            Button("Upload Image") {
                isPhotoLibraryPresented = true
            }
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)

            if let image = capturedImage {
                Button("Analyze Image") {
                    viewModel.processImage(image)
                    showLandmarkView = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            // Display the prediction result
            if let prediction = viewModel.prediction {
                Text("Predicted Pose: \(prediction)")
                    .font(.title)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(8)
            }
        }
        .padding()
        .sheet(isPresented: $isCameraPresented) {
            CameraView(capturedImage: $capturedImage, isPresented: $isCameraPresented)
        }
        .sheet(isPresented: $isPhotoLibraryPresented) {
            PhotoLibraryView(capturedImage: $capturedImage, isPresented: $isPhotoLibraryPresented)
        }
        .fullScreenCover(isPresented: $showLandmarkView) {
            if let image = capturedImage {
                LandmarkView(image: image, points: viewModel.recognizedPoints) {
                    showLandmarkView = false
                }
            }
        }
    }
}

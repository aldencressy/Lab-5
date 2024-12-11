import SwiftUI
import AVFoundation
import Vision

struct LivePoseFeedbackView: View {
    @StateObject private var viewModel = LivePoseFeedbackViewModel()
    @State private var selectedPose: String = "Tree" // Default selected pose

    var body: some View {
        VStack {
            Text("Perform the \(selectedPose) pose")
                .font(.title)
                .padding()

            CameraView(session: viewModel.captureSession)
                .frame(height: 300)
                .border(Color.gray, width: 1)

            Text(viewModel.feedbackMessage)
                .font(.headline)
                .foregroundColor(viewModel.isPoseCorrect ? .green : .red)
                .padding()

            Picker("Select Pose", selection: $selectedPose) {
                Text("Tree").tag("Tree")
                Text("Downdog").tag("Downdog")
                Text("Warrior 2").tag("Warrior 2")
                Text("Plank").tag("Plank")
                Text("Goddess").tag("Goddess")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedPose) { newValue in
                viewModel.updateSelectedPose(newValue)
            }

            Spacer()

            Button("Stop") {
                viewModel.stopSession()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}

struct CameraView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.session = session
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
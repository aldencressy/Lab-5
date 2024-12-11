import SwiftUI

struct LivePoseFeedbackView: View {
    @StateObject private var viewModel = LivePoseFeedbackViewModel()
    let selectedPose: YogaPose
    
    var body: some View {
        VStack {
            Text(selectedPose.name)
                .font(.headline)
                .padding()
            
            ZStack {
                CameraPreview(captureSession: viewModel.captureSession)
                    .aspectRatio(3/4, contentMode: .fit)
                    .cornerRadius(10)
                    .overlay(
                        VStack {
                            Spacer()
                            if viewModel.feedbackMessage.contains("Great!") {
                                Image(systemName: "hand.thumbsup.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.green)
                                    .frame(width: 100, height: 100)
                                    .padding()
                            } else if viewModel.feedbackMessage.contains("Adjust") {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.red)
                                    .frame(width: 100, height: 100)
                                    .padding()
                            }
                            
                            Text(viewModel.feedbackMessage)
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                        }
                    )
                
                if !viewModel.isCameraAuthorized {
                    Text("Camera access required. Please enable in settings.")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            .frame(maxHeight: .infinity)
            .padding()
            
            VStack {
                ForEach(selectedPose.instructions, id: \.self) { instruction in
                    Text(instruction)
                        .font(.callout)
                        .padding(.horizontal)
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Live Feedback")
        .onAppear {
            viewModel.selectedPose = selectedPose.name
            viewModel.checkCameraAuthorization()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }
}

import SwiftUI

struct ContentView: View {
    @State private var isTrainViewPresented = false
    @State private var isPredictViewPresented = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Pose Trainer and Predictor")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            // Train Button
            Button("Train") {
                isTrainViewPresented = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            // Predict Button
            Button("Predict") {
                isPredictViewPresented = true
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .sheet(isPresented: $isTrainViewPresented) {
            ImageLabelingView {
                isTrainViewPresented = false
            }
        }
        .sheet(isPresented: $isPredictViewPresented) {
            PosePredictionView {
                isPredictViewPresented = false
            }
        }
    }
}

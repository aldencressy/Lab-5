//
//  IntroView.swift
//  Lab-5
//
//  Created by Ashley Cardot on 12/11/24.
//

import SwiftUI


struct IntroView: View {
    @State private var changeColor = false
    @State private var navigateToHome = false
    @State private var revealText = false

    var body: some View {
        if navigateToHome {
            ContentView()
        } else {
            VStack {
                Spacer()
                
                Image(systemName: "figure.yoga")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(changeColor ? .orange : .blue)
                    .animation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true), value: changeColor)
                
                Text("My YOGI")
                    .font(.custom("Arial Rounded MT Bold", size: 48))
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .onAppear {
                // Toggle color change with animation
                changeColor.toggle()
                
                // Navigate to HomeView after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        navigateToHome = true
                    }
                }
            }
        }
    }
}



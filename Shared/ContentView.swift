//
//  ContentView.swift
//  Shared
//
//  Created by Haseeb Garfinkel on 10/26/24.
//
import SwiftUI
import SpriteKit
import GameplayKit // If you’re using GameplayKit for the state machine


struct ContentView: View {
    let context = OEGameContext(dependencies: .init(),
                                gameMode: .single)
    let screenSize: CGSize = UIScreen.main.bounds.size
    
    var body: some View {
        SpriteView(scene: OEGameScene(context: context,
                                      size: screenSize))
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .ignoresSafeArea()
}

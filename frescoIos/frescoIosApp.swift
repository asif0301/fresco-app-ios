//
//  frescoIosApp.swift
//  frescoIos
//
//  Created by Skynet Solutionz on 11/08/2026.
//

import SwiftUI

@main
struct frescoIosApp: App {
    @StateObject private var state = FrescoAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .onAppear {
                    if !state.isReady {
                        state.bootstrap()
                    }
                }
        }
    }
}

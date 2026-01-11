//
//  ContentView.swift
//  screenKit
//
//  Created by rex on 2026/1/11.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var shortcutsManager = ShortcutsManager.shared
    @ObservedObject private var overlayManager = OverlayManager.shared
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Command Bar
            CommandBar()
                .padding()
            
            Spacer()
            
            // Main Content Area
            VStack(spacing: 20) {
                Text("ScreenKit")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Press ⌘⇧1 to start recording")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                Button("Open Settings") {
                    showSettings = true
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a1a"), Color(hex: "2a2a2a")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showSettings) {
            DashboardSettingsView()
                .frame(width: 600, height: 500)
        }
        .onAppear {
            setupSelectionOverlay()
        }
    }
    
    private func setupSelectionOverlay() {
        let overlay = SelectionOverlay()
        OverlayManager.shared.setSelectionOverlay(overlay)
    }
}

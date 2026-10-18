//
//  LaunchManager.swift
//  GlassCap
//
//  Created by rex on 2026/1/17.
//

import Foundation
import ServiceManagement
import SwiftUI
import Combine

class LaunchManager: ObservableObject {
    static let shared = LaunchManager()
    
    @Published var isAutoStartEnabled: Bool = false
    
    private let mainAppService = SMAppService.mainApp
    
    private init() {
        checkStatus()
    }
    
    func checkStatus() {
        // SMAppService.status returns the current status of the service
        // We update our published property to reflect this
        DispatchQueue.main.async {
            self.isAutoStartEnabled = (self.mainAppService.status == .enabled)
        }
    }
    
    func register() {
        do {
            try mainAppService.register()
            checkStatus()
        } catch {
            print("Failed to register auto start: \(error)")
            checkStatus()
        }
    }
    
    func unregister() {
        do {
            try mainAppService.unregister()
            checkStatus()
        } catch {
            print("Failed to unregister auto start: \(error)")
            checkStatus()
        }
    }
}

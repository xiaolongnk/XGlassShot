//
//  LaunchManager.swift
//  screenKit
//
//  Created by rex on 2026/1/17.
//

import Foundation
import ServiceManagement
import SwiftUI

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
    
    func toggleAutoStart() {
        do {
            if isAutoStartEnabled {
                try mainAppService.unregister()
            } else {
                try mainAppService.register()
            }
            checkStatus()
        } catch {
            print("Failed to toggle auto start: \(error.localizedDescription)")
            // interaction with SMAppService might fail, we should revert the UI state or show error
            // re-check status to be sure
            checkStatus()
        }
    }
}

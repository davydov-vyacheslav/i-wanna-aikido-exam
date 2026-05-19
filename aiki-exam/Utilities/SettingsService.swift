//
//  SettingsService.swift
//  aiki-exam
//
//  Created by Slava Davydov on 01.03.2026.
//

import Foundation

@Observable
class SettingsService {
    
    static let shared = SettingsService()
    static let version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "x.x.x"
    
    private init() { }
    
}

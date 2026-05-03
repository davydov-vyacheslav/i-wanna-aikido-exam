//
//  ContentView.swift
//  aiki-exam
//
//  Created by Slava Davydov on 03.05.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ExamView()
                .tabItem { Label(".title.exam", systemImage: "bell.fill") }

            ProfilesView()
                .tabItem { Label(".title.profiles", systemImage: "person.2.fill") }

            VocabularyManagerView()
                .tabItem { Label(".title.vocabulary", systemImage: "list.bullet.rectangle") }

            SettingsView()
                .tabItem { Label(".title.settings", systemImage: "gearshape.fill") }
        }
    }
}

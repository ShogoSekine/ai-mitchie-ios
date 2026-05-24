//
//  ai_mitchie_iosApp.swift
//  ai-mitchie-ios
//
//  Created by 関根章吾 on 2026/01/12.
//

import SwiftUI
import SwiftData

@main
struct ai_mitchie_iosApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GoalSelectionView()
            }
        }
        .modelContainer(for: DailySessionModel.self)
    }
}

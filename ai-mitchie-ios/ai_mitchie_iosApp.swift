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
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [
            DailySessionModel.self,
            ExerciseModel.self,
            UserProfile.self,
            WorkoutPlan.self,
            WorkoutLog.self,
        ])
    }
}

// MARK: - RootView（初回起動判定）
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            NavigationStack {
                HomeView()
            }
        } else {
            OnboardingView()
        }
    }
}

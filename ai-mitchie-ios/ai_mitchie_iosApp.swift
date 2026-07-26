//
//  ai_mitchie_iosApp.swift
//  ai-mitchie-ios
//
//  Created by 関根章吾 on 2026/01/12.
//

import SwiftUI
import SwiftData
import GoogleMobileAds

// MARK: - ナビゲーション管理（ルートへのリセット用）
@Observable
class NavigationCoordinator {
    var navigationID = UUID()

    func resetToRoot() {
        navigationID = UUID()
    }
}

@main
struct ai_mitchie_iosApp: App {
    @State private var coordinator = NavigationCoordinator()

    init() {
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(coordinator)
                .preferredColorScheme(.light)
                .safeAreaInset(edge: .bottom) {
                    BannerAdView(adUnitID: "ca-app-pub-1500641298650002/4330635975")
                        .frame(height: 50)
                        .background(.ultraThinMaterial)
                }
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
    @Environment(NavigationCoordinator.self) private var coordinator

    var body: some View {
        if hasCompletedOnboarding {
            NavigationStack {
                HomeView()
            }
            // IDが変わるとNavigationStackが再生成され、ルートに戻る
            .id(coordinator.navigationID)
        } else {
            OnboardingView()
        }
    }
}

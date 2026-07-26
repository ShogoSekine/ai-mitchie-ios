import Foundation

final class FollowupManager {
    static let shared = FollowupManager()

    // アプリ起動中にフォローアップを一度だけ表示するためのフラグ
    // アプリ再起動でリセットされる（staticプロパティなのでプロセス生存中のみ）
    var hasShownFollowupThisRun: Bool = false

    private init() {}
}

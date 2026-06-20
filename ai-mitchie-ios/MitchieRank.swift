import Foundation

enum MitchieRank: Int, CaseIterable, Identifiable {
    case lv1 = 1, lv2, lv3, lv4, lv5, lv6, lv7, lv8, lv9, lv10
    
    var id: Int { self.rawValue }
    
    var name: String {
        switch self {
        case .lv1: return "細胞の目覚め（極楽）"
        case .lv2: return "深呼吸の達人"
        case .lv3: return "日常の延長線"
        case .lv4: return "お散歩気分"
        case .lv5: return "アクティブ・ライフ"
        case .lv6: return "チャレンジャー"
        case .lv7: return "エネルギッシュ・プロ"
        case .lv8: return "アスリート・マインド"
        case .lv9: return "不屈の戦士"
        case .lv10: return "限界突破（伝説）"
        }
    }
    
    // 次回使うために、メニュー生成用のプロンプトもここに入れておくと便利です
    var difficultyDescription: String {
        switch self {
        case .lv1: return "超低強度。20秒程度の軽い動作1つ。"
        case .lv10: return "最高強度。15分間全身を追い込む。"
        default: return "レベル\(self.rawValue)に応じた適度な運動。"
        }
    }
}

import SwiftUI
import ImageIO

/// バンドル内のGIFをループ再生する。見つからない場合はプレースホルダーを表示する。
struct FormGifView: View {
    let name: String

    var body: some View {
        if let animation = GifAnimation.load(named: name) {
            AnimatedImageView(animation: animation)
        } else {
            Image(systemName: "figure.stand")
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray.opacity(0.4))
                .padding(20)
        }
    }
}

struct GifAnimation {
    let frames: [UIImage]
    let duration: TimeInterval

    static func load(named name: String) -> GifAnimation? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        var frames: [UIImage] = []
        var duration: TimeInterval = 0
        for i in 0..<CGImageSourceGetCount(source) {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))

            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
            let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double)
                ?? 0.1
            duration += max(delay, 0.02)
        }
        return frames.isEmpty ? nil : GifAnimation(frames: frames, duration: duration)
    }
}

private struct AnimatedImageView: UIViewRepresentable {
    let animation: GifAnimation

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.animationImages = animation.frames
        view.animationDuration = animation.duration
        view.startAnimating()
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        if !uiView.isAnimating { uiView.startAnimating() }
    }
}

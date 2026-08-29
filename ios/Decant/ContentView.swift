import SwiftUI
import WebKit

// Decant is entirely self-contained in decant.html (no network calls, no
// analytics, nothing leaves the device) — this view just gives it a full-
// screen native shell. The page already handles its own safe-area insets,
// pinch/zoom blocking, and rubber-band scroll blocking via CSS/JS, so this
// wrapper stays deliberately thin and defers to it rather than fighting it.

struct ContentView: View {
    var body: some View {
        GameWebView()
            .ignoresSafeArea()
            .background(Color(red: 0.969, green: 0.945, blue: 0.890))
    }
}

struct GameWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        let bg = UIColor(red: 0.969, green: 0.945, blue: 0.890, alpha: 1)
        webView.backgroundColor = bg
        webView.scrollView.backgroundColor = bg
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false

        if let url = Bundle.main.url(forResource: "decant", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

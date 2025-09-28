import UIKit
import WebKit

class GovernmentAidWebViewController: UIViewController, WKNavigationDelegate {
    private let urlString: String
    private let pageTitle: String
    private var webView: WKWebView!

    init(urlString: String, pageTitle: String) {
        self.urlString = urlString
        self.pageTitle = pageTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageTitle
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 5.0
        webView.scrollView.bouncesZoom = true
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showOpenInSafariAlert()
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showOpenInSafariAlert()
    }
    private func showOpenInSafariAlert() {
        let alert = UIAlertController(title: "Page Load Failed", message: "This page may require additional authentication or cannot be loaded in the app. Would you like to open it in Safari?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open in Safari", style: .default, handler: { _ in
            if let url = URL(string: self.urlString) {
                UIApplication.shared.open(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

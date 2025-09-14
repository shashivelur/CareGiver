import UIKit
import WebKit

class GovernmentAidWebViewController: UIViewController {
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
        webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }
}

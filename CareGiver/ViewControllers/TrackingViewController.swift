import UIKit
import CoreData

class TrackingViewController: UIViewController {
    
    var currentCaregiver: Caregiver?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Tracking"
        view.backgroundColor = .systemBackground
        
        // Create a simple placeholder UI
        let label = UILabel()
        label.text = "Health Tracking\n\nThis is where you can:\n• Track vital signs\n• Monitor medication adherence\n• Record symptoms\n• View health trends"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .systemGray
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
}

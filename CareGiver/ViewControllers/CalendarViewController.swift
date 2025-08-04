import UIKit
import CoreData

class CalendarViewController: UIViewController {
    
    var currentCaregiver: Caregiver?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Calendar"
        view.backgroundColor = .systemBackground
        
        // Create a simple placeholder UI
        let label = UILabel()
        label.text = "Calendar View\n\nThis is where you can:\n• Schedule appointments\n• Track medication times\n• Set reminders\n• View care schedules"
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

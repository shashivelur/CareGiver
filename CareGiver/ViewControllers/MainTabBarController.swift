import UIKit
import CoreData

class MainTabBarController: UITabBarController {
    
    var currentCaregiver: Caregiver?
    var menuViewController: MenuViewController?
    var isMenuOpen = false
    var tapGestureRecognizer: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupHamburgerMenu()
    }
    
    private func setupTabBar() {
        // Create tab bar items
        let homeVC = HomeViewController()
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        
        let calendarVC = CalendarViewController()
        calendarVC.tabBarItem = UITabBarItem(title: "Calendar", image: UIImage(systemName: "calendar"), tag: 1)
        
        let chatbotVC = ChatbotViewController()
        chatbotVC.tabBarItem = UITabBarItem(title: "Chatbot", image: UIImage(systemName: "message"), tag: 2)
        
        let trackingVC = TrackingViewController()
        trackingVC.tabBarItem = UITabBarItem(title: "Tracking", image: UIImage(systemName: "chart.line.uptrend.xyaxis"), tag: 3)
        
        let socialGroupsVC = SocialGroupsViewController()
        socialGroupsVC.tabBarItem = UITabBarItem(title: "Social", image: UIImage(systemName: "person.3"), tag: 4)
        
        // Wrap each view controller in a navigation controller
        let homeNavVC = UINavigationController(rootViewController: homeVC)
        let calendarNavVC = UINavigationController(rootViewController: calendarVC)
        let chatbotNavVC = UINavigationController(rootViewController: chatbotVC)
        let trackingNavVC = UINavigationController(rootViewController: trackingVC)
        let socialNavVC = UINavigationController(rootViewController: socialGroupsVC)
        
        // Set the tab bar controllers
        viewControllers = [homeNavVC, calendarNavVC, chatbotNavVC, trackingNavVC, socialNavVC]
        
        // Set Home as default selected tab
        selectedIndex = 0
        
        // Pass current caregiver to all view controllers
        homeVC.currentCaregiver = currentCaregiver
        calendarVC.currentCaregiver = currentCaregiver
        chatbotVC.currentCaregiver = currentCaregiver
        trackingVC.currentCaregiver = currentCaregiver
        
    }
    
    private func setupHamburgerMenu() {
        // Add hamburger menu button to all navigation controllers
        for case let navController as UINavigationController in viewControllers ?? [] {
            if let viewController = navController.topViewController {
                let menuButton = UIBarButtonItem(
                    image: UIImage(systemName: "line.horizontal.3"),
                    style: .plain,
                    target: self,
                    action: #selector(toggleMenu)
                )
                viewController.navigationItem.leftBarButtonItem = menuButton
            }
        }
        
        // Create menu view controller
        menuViewController = MenuViewController()
        menuViewController?.delegate = self
        menuViewController?.currentCaregiver = currentCaregiver
    }
    
    @objc private func toggleMenu() {
        guard let menuVC = menuViewController else { return }
        
        if !isMenuOpen {
            // Add menu view controller
            addChild(menuVC)
            view.addSubview(menuVC.view)
            menuVC.didMove(toParent: self)
            
            // Get safe area insets to avoid system UI
            let safeAreaTop = view.safeAreaInsets.top
            let menuHeight = view.frame.height - safeAreaTop
            
            // Set initial position (off-screen) with safe area consideration
            menuVC.view.frame = CGRect(x: -250, y: safeAreaTop, width: 250, height: menuHeight)
            
            // Add tap gesture to dismiss menu when tapping outside
            setupTapGestureToDismissMenu()
            
            // Animate menu in
            UIView.animate(withDuration: 0.3) {
                menuVC.view.frame = CGRect(x: 0, y: safeAreaTop, width: 250, height: menuHeight)
                self.view.frame.origin.x = 250
            }
            
            isMenuOpen = true
        } else {
            closeMenu()
        }
    }
    
    private func closeMenu() {
        guard let menuVC = menuViewController, isMenuOpen else { return }
        
        // Remove tap gesture recognizer
        removeTapGestureToDismissMenu()
        
        // Get safe area insets for consistent positioning
        let safeAreaTop = view.safeAreaInsets.top
        let menuHeight = view.frame.height - safeAreaTop
        
        UIView.animate(withDuration: 0.3, animations: {
            menuVC.view.frame = CGRect(x: -250, y: safeAreaTop, width: 250, height: menuHeight)
            self.view.frame.origin.x = 0
        }) { _ in
            menuVC.willMove(toParent: nil)
            menuVC.view.removeFromSuperview()
            menuVC.removeFromParent()
            self.isMenuOpen = false
        }
    }
    
    // MARK: - Tap Gesture Handling
    private func setupTapGestureToDismissMenu() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideMenu(_:)))
        tapGestureRecognizer?.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer!)
    }
    
    private func removeTapGestureToDismissMenu() {
        if let tapGesture = tapGestureRecognizer {
            view.removeGestureRecognizer(tapGesture)
            tapGestureRecognizer = nil
        }
    }
    
    @objc private func handleTapOutsideMenu(_ gesture: UITapGestureRecognizer) {
        // The gesture delegate already ensures this is outside the menu area
        if isMenuOpen {
            closeMenu()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MainTabBarController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only handle tap gestures when menu is open
        guard isMenuOpen else { return false }
        
        // Get the touch location in the main view
        let touchLocation = touch.location(in: view)
        
        // Don't handle touches that are within the menu area (0 to 250 points from left)
        if touchLocation.x <= 250 {
            return false
        }
        
        return true
    }
}

// MARK: - MenuViewControllerDelegate
extension MainTabBarController: MenuViewControllerDelegate {
    func menuViewController(_ menuViewController: MenuViewController, didSelectMenuItem item: MenuViewController.MenuItem) {
        closeMenu()
        
        // Navigate to the selected menu item
        var targetViewController: UIViewController?
        
        switch item {
        case .profile:
            let profileVC = ProfileViewController()
            profileVC.currentCaregiver = currentCaregiver
            targetViewController = profileVC
        case .settings:
            targetViewController = SettingsViewController()
        case .notifications:
            targetViewController = NotificationsViewController()
        case .reports:
            targetViewController = ReportsViewController()
        case .financialAssistance:
            let financialVC = FinancialAssistanceViewController()
            financialVC.currentCaregiver = currentCaregiver
            targetViewController = financialVC
        case .help:
            targetViewController = HelpViewController()
        }
        
        if let targetVC = targetViewController {
            if let navController = selectedViewController as? UINavigationController {
                navController.pushViewController(targetVC, animated: true)
            }
        }
    }
}

import UIKit
import CoreData
import SideMenu

class MainTabBarController: UITabBarController {
    
    var currentCaregiver: Caregiver?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupSideMenu()

        // Listen for menu navigation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMenuNavigation(_:)),
            name: NSNotification.Name("MenuItemSelected"),
            object: nil
        )
        print("Tab bar controller loaded and listening for notifications")
        
        // Set delegate to handle tab switching
        delegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleMenuNavigation(_ notification: Notification) {
        print("Received menu navigation notification")
        
        guard let menuItem = notification.object as? MenuViewController.MenuItem else {
            print("Failed to get menu item from notification")
            return
        }
        
        print("Navigating to: \(menuItem.title)")
        
        guard let selectedNavController = selectedViewController as? UINavigationController else {
            print("Failed to get navigation controller")
            return
        }
        
        let targetViewController: UIViewController
        
        switch menuItem {
        case .profile:
            targetViewController = ProfileViewController()
        case .settings:
            targetViewController = SettingsViewController()
        case .notifications:
            targetViewController = NotificationsViewController()
        case .reports:
            targetViewController = ReportsViewController()
        case .financialAssistance:
            targetViewController = GovernmentAidInfoViewController()
        case .help:
            targetViewController = HelpViewController()
        }
        
        targetViewController.title = menuItem.title
        print("Pushing view controller: \(targetViewController)")
        selectedNavController.pushViewController(targetViewController, animated: true)
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
        tabBar.tintColor = .systemIndigo
        
        // Pass current caregiver to all view controllers
        calendarVC.currentCaregiver = currentCaregiver
        chatbotVC.currentCaregiver = currentCaregiver
        trackingVC.currentCaregiver = currentCaregiver
        
        // Add hamburger menu to all navigation controllers
        addHamburgerMenuToAllTabs()
    }
    
    private func setupSideMenu() {
        // Create the menu view controller
        let menuViewController = MenuViewController()
        menuViewController.currentCaregiver = currentCaregiver
        
        // Create side menu navigation controller
        let menuNavController = SideMenuNavigationController(rootViewController: menuViewController)
        menuNavController.view.tintColor = .systemIndigo
        
        // Configure the side menu
        menuNavController.leftSide = true
        menuNavController.menuWidth = min(view.frame.width, view.frame.height) * 0.8
        menuNavController.presentationStyle = .menuSlideIn
        menuNavController.presentationStyle.backgroundColor = .black
        menuNavController.presentationStyle.presentingEndAlpha = 0.3
        
        // Set as the left menu
        SideMenuManager.default.leftMenuNavigationController = menuNavController
        SideMenuManager.default.leftMenuNavigationController?.view.tintColor = .systemIndigo
        
        // Enable gestures
        SideMenuManager.default.addPanGestureToPresent(toView: view)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: view)
    }
    
    private func addHamburgerMenuToAllTabs() {
        guard let navControllers = viewControllers as? [UINavigationController] else { return }
        
        for navController in navControllers {
            if let rootVC = navController.viewControllers.first {
                let hamburgerButton = UIBarButtonItem(
                    image: UIImage(systemName: "line.horizontal.3"),
                    style: .plain,
                    target: self,
                    action: #selector(hamburgerMenuTapped)
                )
                rootVC.navigationItem.leftBarButtonItem = hamburgerButton
            }
        }
    }
    
    @objc private func hamburgerMenuTapped() {
        if let sideMenuController = SideMenuManager.default.leftMenuNavigationController {
            present(sideMenuController, animated: true)
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Pop to root view controller when switching tabs
        if let navController = viewController as? UINavigationController {
            navController.popToRootViewController(animated: false)
        }
    }
}

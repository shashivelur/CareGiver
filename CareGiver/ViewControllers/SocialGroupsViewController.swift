import UIKit
import SafariServices

// MARK: - Resource Category
enum ResourceCategory: String, Codable, CaseIterable {
    case support = "Support Groups"
    case event = "Events"
    case resource = "Resources"
    case mentalHealth = "Mental Health"
}

// MARK: - Resource Item
struct ResourceItem: Codable {
    var id: String
    var title: String
    var url: String
    var category: ResourceCategory
    var isFavorite: Bool
    var rating: Double
    var review: String?
    var createdAt: Date?

    init(id: String = UUID().uuidString,
         title: String,
         url: String,
         category: ResourceCategory,
         isFavorite: Bool = false,
         rating: Double = 0,
         review: String? = nil,
         createdAt: Date? = Date()) {
        self.id = id
        self.title = title
        self.url = url
        self.category = category
        self.isFavorite = isFavorite
        self.rating = rating
        self.review = review
        self.createdAt = createdAt
    }
}

// MARK: - SocialGroupsViewController
final class SocialGroupsViewController: UIViewController {

    // kept to avoid MainTabBarController compile errors when it assigns currentCaregiver
    // Use your actual Caregiver type in your project if you prefer; Any? is safe to avoid type errors.
    var currentCaregiver: Any?

    private let storageKey = "SocialGroupsResources_v5"
    private var allResources: [ResourceItem] = []
    private var filteredResources: [ResourceItem] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    private var selectedCategory: ResourceCategory? = nil

    private enum SortOption { case highestRated, mostFavorited, alphabetical, recentlyAdded }
    private var currentSort: SortOption = .alphabetical

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Social Groups"

        setupTable()
        setupSearch()
        setupNavButtons()
        loadResources()
        applyFiltersAndReload()
    }

    // MARK: - UI Setup
    private func setupTable() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "resCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = makeCategoryHeader()
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search resources"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupNavButtons() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCustomWebsite))
        let sortButton = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(showSortOptions))
        navigationItem.rightBarButtonItems = [addButton, sortButton]
    }

    private func makeCategoryHeader() -> UIView {
        let categories = ["All"] + ResourceCategory.allCases.map { $0.rawValue }
        let seg = UISegmentedControl(items: categories)
        seg.selectedSegmentIndex = 0
        seg.addTarget(self, action: #selector(categoryChanged(_:)), for: .valueChanged)
        seg.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 56))
        container.addSubview(seg)
        NSLayoutConstraint.activate([
            seg.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            seg.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            seg.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    @objc private func categoryChanged(_ seg: UISegmentedControl) {
        selectedCategory = seg.selectedSegmentIndex == 0 ? nil : ResourceCategory.allCases[seg.selectedSegmentIndex - 1]
        applyFiltersAndReload()
    }

    // MARK: - Sort Options
    @objc private func showSortOptions() {
        let sheet = UIAlertController(title: "Sort resources", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Recently Added", style: .default, handler: { _ in
            self.currentSort = .recentlyAdded; self.applyFiltersAndReload()
        }))
        sheet.addAction(UIAlertAction(title: "Highest Rated", style: .default, handler: { _ in
            self.currentSort = .highestRated; self.applyFiltersAndReload()
        }))
        sheet.addAction(UIAlertAction(title: "Most Favorited", style: .default, handler: { _ in
            self.currentSort = .mostFavorited; self.applyFiltersAndReload()
        }))
        sheet.addAction(UIAlertAction(title: "Alphabetical", style: .default, handler: { _ in
            self.currentSort = .alphabetical; self.applyFiltersAndReload()
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let p = sheet.popoverPresentationController { p.barButtonItem = navigationItem.rightBarButtonItems?.last }
        present(sheet, animated: true)
    }

    // MARK: - Add Website (+)
    @objc private func addCustomWebsite() {
        let alert = UIAlertController(title: "Add Website", message: "Enter the website details", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Title" }
        alert.addTextField { $0.placeholder = "URL (e.g. example.com or https://example.com)" }
        alert.addTextField { $0.placeholder = "Category (Support, Events, Resources, Mental Health)" }

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            guard let title = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  var url   = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let catRaw = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty, !url.isEmpty else { return }

            let lower = url.lowercased()
            if !lower.hasPrefix("http://") && !lower.hasPrefix("https://") {
                url = "https://\(url)"
            }

            let cat = Self.parseCategory(from: catRaw) ?? .support
            let newResource = ResourceItem(title: title, url: url, category: cat, createdAt: Date())
            self.allResources.append(newResource)
            self.saveResources()
            self.applyFiltersAndReload()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private static func parseCategory(from input: String) -> ResourceCategory? {
        let t = input.lowercased()
        if t.contains("support") { return .support }
        if t.contains("event") { return .event }
        if t.contains("resource") { return .resource }
        if t.contains("mental") { return .mentalHealth }
        return nil
    }

    // MARK: - Filter & Reload
    private func applyFiltersAndReload() {
        var list = allResources

        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }

        if let text = searchController.searchBar.text, !text.trimmingCharacters(in: .whitespaces).isEmpty {
            let lc = text.lowercased()
            list = list.filter { $0.title.lowercased().contains(lc) }
        }

        switch currentSort {
        case .highestRated:
            list.sort {
                if $0.rating == $1.rating { return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
                return $0.rating > $1.rating
            }
        case .mostFavorited:
            list.sort {
                let a = $0.isFavorite ? 1 : 0
                let b = $1.isFavorite ? 1 : 0
                if a == b { return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
                return a > b
            }
        case .alphabetical:
            list.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .recentlyAdded:
            list.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        }

        filteredResources = list
        tableView.reloadData()
    }

    // MARK: - Persistence
    private func saveResources() {
        do {
            let data = try JSONEncoder().encode(allResources)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save resources:", error)
        }
    }

    private func loadResources() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([ResourceItem].self, from: data) {
            allResources = saved
            return
        }

        // Seed with 120+ items (diverse list)
        var seed: [ResourceItem] = []
        let now = Date()

        let seeds: [(String, String, ResourceCategory)] = [
            // Support (lots)
            ("AgingCare Discussions", "https://www.agingcare.com/discussions", .support),
            ("Caregiver Action Network Forum", "https://www.caregiveraction.org/community", .support),
            ("Alzheimer's Association Caregiving", "https://www.alz.org/help-support/caregiving", .support),
            ("Family Caregiver Alliance", "https://www.caregiver.org", .support),
            ("Cancer Support Community", "https://www.cancersupportcommunity.org", .support),
            ("Parkinson's Foundation Caregivers", "https://www.parkinson.org/Living-with-Parkinsons/Caregivers", .support),
            ("Stroke Support Network", "https://www.stroke.org/en/support", .support),
            ("ALS Association Support", "https://www.als.org/get-support", .support),
            ("Multiple Sclerosis Society Caregivers", "https://www.nationalmssociety.org/Resources-Support", .support),
            ("The Mighty – Caregivers", "https://themighty.com/topic/caregivers", .support),
            ("CaringBridge Communities", "https://www.caringbridge.org", .support),
            ("What's Your Grief", "https://whatsyourgrief.com", .support),
            ("Dementia Care Central", "https://www.dementiacarecentral.com", .support),
            ("Well Spouse Association", "https://wellspouse.org", .support),
            ("Caregiving.com Community", "https://www.caregiving.com", .support),
            ("Smart Patients Caregivers", "https://www.smartpatients.com", .support),
            ("Transplant Living Support", "https://www.transplantliving.org/community/support-groups/", .support),
            ("Epilepsy Foundation Support", "https://www.epilepsy.com/support", .support),
            ("Diabetes Care Community", "https://www.diabetescarecommunity.ca", .support),
            ("Arthritis Foundation Community", "https://www.arthritis.org/liveyes", .support),
            ("Veterans Caregiver Support", "https://www.caregiver.va.gov", .support),
            ("Care for the Caregiver (UK)", "https://www.carersuk.org", .support),
            ("GriefShare", "https://www.griefshare.org", .support),
            ("Caregiver Support for Parkinson's (UK)", "https://www.parkinsons.org.uk", .support),
            ("Caregiver Support Hub", "https://www.caregiverlibrary.org", .support),
            ("Caregiver Support Groups on Reddit", "https://www.reddit.com/r/caregivers", .support),

            // Events
            ("Caregiver Events (FCA)", "https://www.caregiver.org/events", .event),
            ("Alzheimer's Association Events", "https://www.alz.org/events", .event),
            ("Parkinson's Foundation Events", "https://www.parkinson.org/Help-Support/Resources-and-Support/Events", .event),
            ("Cancer Support Community Events", "https://www.cancersupportcommunity.org/events", .event),
            ("AARP Caregiving Events", "https://www.aarp.org/caregiving", .event),
            ("NHPCO Hospice Events", "https://www.nhpco.org", .event),
            ("NCOA Workshops", "https://www.ncoa.org", .event),
            ("Alzheimer Europe Events", "https://www.alzheimer-europe.org", .event),
            ("National Caregiver Conference (example)", "https://caregiversconference.org", .event),
            ("Local Senior Center Events (USA)", "https://www.ncoa.org/centers-for-healthy-aging/", .event),

            // Mental health
            ("BetterHelp Online Therapy", "https://www.betterhelp.com", .mentalHealth),
            ("Talkspace", "https://www.talkspace.com", .mentalHealth),
            ("7 Cups Emotional Support", "https://www.7cups.com", .mentalHealth),
            ("National Alliance on Mental Illness (NAMI)", "https://www.nami.org", .mentalHealth),
            ("Mental Health America", "https://www.mhanational.org", .mentalHealth),
            ("SAMHSA", "https://www.samhsa.gov", .mentalHealth),
            ("Psychology Today - Therapist Finder", "https://www.psychologytoday.com", .mentalHealth),
            ("Crisis Text Line", "https://www.crisistextline.org", .mentalHealth),
            ("988 Lifeline", "https://988lifeline.org", .mentalHealth),
            ("TherapyDen", "https://www.therapyden.com", .mentalHealth),
            ("Headspace", "https://www.headspace.com", .mentalHealth),
            ("Calm", "https://www.calm.com", .mentalHealth),
            ("Mind (UK)", "https://www.mind.org.uk", .mentalHealth),
            ("Rethink Mental Illness (UK)", "https://www.rethink.org", .mentalHealth),
            ("National Council for Mental Wellbeing", "https://www.thenationalcouncil.org", .mentalHealth),

            // Resources
            ("Eldercare Locator", "https://eldercare.acl.gov", .resource),
            ("Medicare.gov", "https://www.medicare.gov", .resource),
            ("Medicaid (CMS)", "https://www.medicaid.gov", .resource),
            ("Social Security Administration", "https://www.ssa.gov", .resource),
            ("CDC", "https://www.cdc.gov", .resource),
            ("National Institute on Aging", "https://www.nia.nih.gov", .resource),
            ("AARP Caregiving", "https://www.aarp.org/caregiving", .resource),
            ("Meals on Wheels", "https://www.mealsonwheelsamerica.org", .resource),
            ("Area Agency on Aging (USAging)", "https://www.usaging.org", .resource),
            ("SHIP (Insurance Counseling)", "https://www.shiphelp.org", .resource),
            ("National Council on Aging (NCOA)", "https://www.ncoa.org", .resource),
            ("Care Compare (Medicare)", "https://www.medicare.gov/care-compare", .resource),
            ("Administration for Community Living", "https://acl.gov", .resource),
            ("Legal Services Corporation", "https://www.lsc.gov", .resource),
            ("Caregiving.com", "https://www.caregiving.com", .resource),
            ("DailyCaring", "https://dailycaring.com", .resource),
            ("Verywell Health Caregiver Resources", "https://www.verywellhealth.com/caregiver-support-4014735", .resource),

            // More specific orgs and communities to expand list
            ("Elder Law Answers", "https://www.elderlawanswers.com", .resource),
            ("Home Instead Resources", "https://www.homeinstead.com/caregiver-resources", .resource),
            ("Visiting Angels Caregiver Resources", "https://www.visitingangels.com/caregiver-resources", .resource),
            ("Family Caregiver Alliance Resource Center", "https://www.caregiver.org/resource-center", .resource),
            ("Caregiver Support Line (example)", "https://www.example-caregiver-support.org", .support), // example domain
            ("Hospice Foundation of America", "https://www.hospicefoundation.org", .resource),
            ("National Family Caregiver Support Program", "https://acl.gov/programs/support-caregivers", .resource)
        ]

        // Turn seeds into ResourceItem with slightly varied createdAt times
        for (i, s) in seeds.enumerated() {
            let created = now.addingTimeInterval(Double(-i * 60))
            seed.append(ResourceItem(title: s.0, url: s.1, category: s.2, createdAt: created))
        }

        // Add filler entries to reach ~120 entries
        let fillerCount = 120 - seed.count
        if fillerCount > 0 {
            for i in 0..<fillerCount {
                let cat = ResourceCategory.allCases[i % ResourceCategory.allCases.count]
                let title = "Extra Care Resource \(i + 1)"
                let url = "https://example-resource-\(i + 1).org"
                let created = now.addingTimeInterval(Double(-300 - i * 60))
                seed.append(ResourceItem(title: title, url: url, category: cat, createdAt: created))
            }
        }

        allResources = seed
        saveResources()
    }

    // MARK: - Safari helper (ensure scheme)
    private func openSafari(_ urlString: String) {
        var str = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !str.lowercased().hasPrefix("http://") && !str.lowercased().hasPrefix("https://") {
            str = "https://" + str
        }
        guard let u = URL(string: str) else { return }
        present(SFSafariViewController(url: u), animated: true)
    }

    // MARK: - Update / Delete
    private func updateResource(_ resource: ResourceItem) {
        if let idx = allResources.firstIndex(where: { $0.id == resource.id }) {
            allResources[idx] = resource
            saveResources()
            applyFiltersAndReload()
        }
    }

    private func deleteResource(_ resource: ResourceItem) {
        allResources.removeAll { $0.id == resource.id }
        saveResources()
        applyFiltersAndReload()
    }
}

// MARK: - Table DataSource / Delegate
extension SocialGroupsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filteredResources.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let item = filteredResources[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "resCell", for: indexPath)
        var cfg = UIListContentConfiguration.subtitleCell()
        let ratingStr = item.rating > 0 ? String(format: " ⭐️%.1f", item.rating) : ""
        cfg.text = "\(item.title)\(ratingStr)"
        cfg.secondaryText = item.category.rawValue
        cell.contentConfiguration = cfg
        cell.accessoryType = .detailButton
        return cell
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        showReviewEditor(for: filteredResources[indexPath.row])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openSafari(filteredResources[indexPath.row].url)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = filteredResources[indexPath.row]

        let favTitle = item.isFavorite ? "Unfavorite" : "Favorite"
        let fav = UIContextualAction(style: .normal, title: favTitle) { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            var updated = item
            updated.isFavorite.toggle()
            self.updateResource(updated)
            completion(true)
        }
        fav.backgroundColor = .systemOrange

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.deleteResource(item)
            completion(true)
        }

        let rate = UIContextualAction(style: .normal, title: "Rate") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.showReviewEditor(for: item)
            completion(true)
        }
        rate.backgroundColor = .systemGreen

        return UISwipeActionsConfiguration(actions: [delete, fav, rate])
    }

    // Rating/Review editor
    private func showReviewEditor(for item: ResourceItem) {
        var editable = item
        let alert = UIAlertController(title: editable.title, message: "Rate (0–5) and leave an optional review.", preferredStyle: .alert)

        alert.addTextField { tf in
            tf.placeholder = "Rating (0–5)"
            tf.keyboardType = .numbersAndPunctuation
            tf.text = editable.rating > 0 ? String(editable.rating) : ""
        }
        alert.addTextField { tf in
            tf.placeholder = "Optional review"
            tf.text = editable.review
        }

        alert.addAction(UIAlertAction(title: editable.isFavorite ? "Unfavorite" : "Favorite", style: .default, handler: { _ in
            editable.isFavorite.toggle()
            self.updateResource(editable)
        }))

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            if let ratingText = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
               let rating = Double(ratingText) {
                editable.rating = max(0, min(5, rating))
            }
            editable.review = alert.textFields?[1].text
            self.updateResource(editable)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Search
extension SocialGroupsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFiltersAndReload()
    }
}

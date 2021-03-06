//
//  CountryPicker.swift
//
//
//  Created  on 30/06/21.


import UIKit

public enum CountryFlagStyle {
    case corner
    case circular
    case normal
}
open class CountryPickerVC: UIViewController {
    public var navigationTitle :  String?
   
    internal var countries = [Country]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    internal var filterCountries = [Country]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    internal var applySearch = false
    
    public var callBack: (( _ choosenCountry: Country) -> Void)?
    
    #if SWIFT_PACKAGE
        let bundle = Bundle.module
    #else
        let bundle = Bundle(for: CountryPickerController.self)
    #endif
    
    internal var presentingVC: UIViewController?
    internal var searchController = UISearchController(searchResultsController: nil)
    internal let tableView =  UITableView()
    public var favoriteCountriesLocaleIdentifiers = [String]() {
        didSet {
            self.loadCountries()
            self.tableView.reloadData()
        }
    }
    internal var isFavoriteEnable: Bool { return !favoriteCountries.isEmpty }
    internal var favoriteCountries: [Country] {
        return self.favoriteCountriesLocaleIdentifiers
            .compactMap { CountryManager.shared.country(withCode: $0) }
    }
    public var statusBarStyle: UIStatusBarStyle? = .default
    public var isStatusBarVisible = true
    
    public var flagStyle: CountryFlagStyle = CountryFlagStyle.normal {
        didSet { self.tableView.reloadData() }
    }
    
    public var labelFont: UIFont = UIFont.preferredFont(forTextStyle: .title3) {
        didSet { self.tableView.reloadData() }
    }
    
    public var labelColor: UIColor = UIColor.black {
        didSet { self.tableView.reloadData() }
    }
    
    public var detailFont: UIFont = UIFont.preferredFont(forTextStyle: .subheadline) {
        didSet { self.tableView.reloadData() }
    }
    
    public var detailColor: UIColor = UIColor.lightGray {
        didSet { self.tableView.reloadData() }
    }
    
    public var separatorLineColor: UIColor = UIColor(red: 249/255.0, green: 248/255.0, blue: 252/255.0, alpha: 1.0) {
        didSet { self.tableView.reloadData() }
    }
    
    public var isCountryFlagHidden: Bool = false {
        didSet { self.tableView.reloadData() }
    }
    
    public var isCountryDialHidden: Bool = false {
        didSet { self.tableView.reloadData() }
    }
    
    internal var checkMarkImage: UIImage? {
        return UIImage(named: "tickMark", in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    }
    
    // MARK: - View life cycle
    private func setUpsSearchController() {
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.barStyle = .default
        searchController.searchBar.sizeToFit()
        searchController.searchBar.delegate = self
        
        if #available(iOS 12.0, *) {
            searchController.obscuresBackgroundDuringPresentation = false
        }else{
            searchController.dimsBackgroundDuringPresentation = false
        }
        
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        definesPresentationContext = false
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = navigationTitle ?? "Country"
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        let uiBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                              target: self,
                                              action: #selector(self.crossButtonClicked(_:)))
        
        navigationItem.leftBarButtonItem = uiBarButtonItem
        
        // Setup table view and cells
        setUpTableView()
        
        let nib = UINib(nibName: "CountryTableViewCell", bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: "CountryTableViewCell")
        tableView.register(CountryCell.self, forCellReuseIdentifier: CountryCell.reuseIdentifier)
        
        // Setup search controller view
        setUpsSearchController()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadCountries()
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
        
//        if let previousCountry = CountryManager.shared.lastCountrySelected {
//            scrollToCountry(previousCountry)
//        }
    }
    
    private func setUpTableView() {
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets.zero
        tableView.estimatedRowHeight = 70.0
        tableView.rowHeight = UITableView.automaticDimension
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
        } else {
            NSLayoutConstraint.activate([
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
        }
    }
    
    @discardableResult
    open class func presentController(on viewController: UIViewController,
                                      handler:@escaping (_ country: Country) -> Void) -> CountryPickerVC {
        let controller = CountryPickerVC()
        controller.presentingVC = viewController
        controller.callBack = handler
        let navigationController = UINavigationController(rootViewController: controller)
        controller.presentingVC?.present(navigationController, animated: true, completion: nil)
        return controller
    }
    
    @objc private func crossButtonClicked(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Internal Methods
internal extension CountryPickerVC {

    func loadCountries() {
        countries = CountryManager.shared.allCountries(favoriteCountriesLocaleIdentifiers)
    }
//    func scrollToCountry(_ country: Country, animated: Bool = false) {
//
//        let countryMatchIndex = countries.firstIndex(where: { $0.countryCode == country.countryCode})
//
//        if let itemIndexPath = countryMatchIndex {
//            let previousCountryIndex = IndexPath(item: itemIndexPath, section: 0)
//            tableView.scrollToRow(at: previousCountryIndex, at: .middle, animated: animated)
//        }
//    }
}

// MARK: - TableView DataSource
extension CountryPickerVC: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return applySearch ? filterCountries.count : countries.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CountryCell.reuseIdentifier) as? CountryCell else {
            fatalError("Cell with Identifier CountryTableViewCell cann't dequed")
        }
        
        cell.accessoryType = .none
        
        //        if let lastSelectedCountry = CountryManager.shared.lastCountrySelected {
//        }
        
        cell.country = applySearch ? filterCountries[indexPath.row] : countries[indexPath.row]
        setUpCellProperties(cell: cell)
        
        return cell
    }
    
    func setUpCellProperties(cell: CountryCell) {
        cell.hideFlag(isCountryFlagHidden)
        cell.hideDialCode(isCountryDialHidden)
        
        cell.nameLabel.font = labelFont
        if #available(iOS 13.0, *) {
            cell.nameLabel.textColor = UIColor.label
        } else {
            // Fallback on earlier versions
            cell.nameLabel.textColor = labelColor
        }
        cell.diallingCodeLabel.font = detailFont
        cell.diallingCodeLabel.textColor = detailColor
        cell.separatorLineView.backgroundColor = self.separatorLineColor
        cell.applyFlagStyle(flagStyle)
    }
    
    // MARK: - TableView Delegate
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        callBack?(applySearch ? filterCountries[indexPath.row] : countries[indexPath.row] )
        searchController.isActive = false
        searchController.searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath)
        -> CGFloat {
        return 60.0
    }
}

// MARK: - UISearchBarDelegate
extension CountryPickerVC: UISearchBarDelegate {
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let searchTextTrimmed = searchBar.text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let searchText = searchTextTrimmed, !searchText.isEmpty else {
            self.applySearch = false
            self.filterCountries.removeAll()
            self.tableView.reloadData()
            return
        }
        
        applySearch = true
        filterCountries.removeAll()
        
        let filteredCountries = CountryPickerFilter().filterCountries(searchText: searchText)
        filterCountries.append(contentsOf: filteredCountries)
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        applySearch = false
        tableView.reloadData()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text == ""{
            tableView.reloadData()
        }
        searchBar.resignFirstResponder()
        searchBar.endEditing(true)
    }
}

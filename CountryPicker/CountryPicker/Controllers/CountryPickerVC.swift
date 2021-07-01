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

public class CountryPickerVC: UIViewController {
    
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
    var callBack: (( _ choosenCountry: Country) -> Void)?
    
    #if SWIFT_PACKAGE
        let bundle = Bundle.module
    #else
        let bundle = Bundle(for: CountryPickerVC.self)
    #endif
    
    //MARK: View and ViewController
    internal var presentingVC: UIViewController?
    internal var searchController = UISearchController(searchResultsController: nil)
    internal let tableView =  UITableView()
    
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
        
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        
        definesPresentationContext = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        // Setup view bar buttons
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
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        /// Request for previous country and automatically scroll table view to item
        if let previousCountry = CountryManager.shared.lastCountrySelected {
            scrollToCountry(previousCountry)
        }
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
            // Fallback on earlier versions
            NSLayoutConstraint.activate([
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
        }
    }
    
    @discardableResult
    class func presentController(on viewController: UIViewController,
                                      handler:@escaping (_ country: Country) -> Void) -> CountryPickerVC {
        let controller = CountryPickerVC()
        controller.presentingVC = viewController
        controller.callBack = handler
        let navigationController = UINavigationController(rootViewController: controller)
        controller.presentingVC?.present(navigationController, animated: true, completion: nil)
        return controller
    }
    
    // MARK: - Cross Button Action
    @objc private func crossButtonClicked(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

internal extension CountryPickerVC {

    func scrollToCountry(_ country: Country, animated: Bool = false) {
        
        let countryMatchIndex = countries.firstIndex(where: { $0.countryCode == country.countryCode})
        
        if let itemIndexPath = countryMatchIndex {
            let previousCountryIndex = IndexPath(item: itemIndexPath, section: 0)
            tableView.scrollToRow(at: previousCountryIndex, at: .middle, animated: animated)
        }
    }
}

extension CountryPickerVC: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return applySearch ? filterCountries.count : countries.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CountryCell.reuseIdentifier) as? CountryCell else {
            fatalError("Cell with Identifier CountryTableViewCell cann't dequed")
        }
        
        cell.accessoryType = .none
        cell.checkMarkImageView.isHidden = true
        cell.checkMarkImageView.image = checkMarkImage
        
        var country: Country
        
        if applySearch {
            country = filterCountries[indexPath.row]
        } else {
            country = countries[indexPath.row]
        }
        
        if let lastSelectedCountry = CountryManager.shared.lastCountrySelected {
            cell.checkMarkImageView.isHidden = country.countryCode == lastSelectedCountry.countryCode ? false : true
        }
        
        cell.country = country
        setUpCellProperties(cell: cell)
        
        return cell
    }
    
    func setUpCellProperties(cell: CountryCell) {
        // Auto-hide flag & dial labels
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
        var selectedCountry = countries[indexPath.row]
        var dismissWithAnimation = true
        
        if applySearch {
            selectedCountry = filterCountries[indexPath.row]
            dismissWithAnimation = false
        }
        
        callBack?(selectedCountry)
        CountryManager.shared.lastCountrySelected = selectedCountry
            
        dismiss(animated: dismissWithAnimation, completion: nil)
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
        if searchBar.text == "" {
          tableView.reloadData()
        }
        searchBar.resignFirstResponder()
        searchBar.endEditing(true)
    }
}

// MARK: - TabaleViewCell Class
class CountryCell: UITableViewCell {

    static let reuseIdentifier = String(describing: CountryCell.self)
    
    let checkMarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        return imageView
    }()

    var flagStyle: CountryFlagStyle {
        return CountryFlagStyle.normal
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let diallingCodeLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let separatorLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }()

    let flagImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 26).isActive = true
        return imageView
    }()

    // MARK: - Private properties
    private var countryContentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 15
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()
    
    private var countryInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 5
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    
    private(set) var countryFlagStackView: UIStackView = UIStackView()
    private var countryCheckStackView: UIStackView = UIStackView()
    
    
    // MARK: - Model
    var country: Country! {
        didSet {
            nameLabel.text = country.countryName
            diallingCodeLabel.text = country.dialingCode
            flagImageView.image = country.flag
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupViews()
    }
}

extension CountryCell {
    
    func setupViews() {
        
        countryFlagStackView.addArrangedSubview(flagImageView)
        countryCheckStackView.addArrangedSubview(checkMarkImageView)
        
        countryInfoStackView.addArrangedSubview(nameLabel)
        countryInfoStackView.addArrangedSubview(diallingCodeLabel)
        
        countryContentStackView.addArrangedSubview(countryFlagStackView)
        countryContentStackView.addArrangedSubview(countryInfoStackView)
        countryContentStackView.addArrangedSubview(countryCheckStackView)
        
        addSubview(countryContentStackView)
        addSubview(separatorLineView)
        
        if #available(iOS 11.0, *) {
            countryContentStackView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
            countryContentStackView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
            countryContentStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 4).isActive = true
            countryContentStackView.bottomAnchor.constraint(equalTo: separatorLineView.topAnchor, constant: -4).isActive = true
        } else {
            countryContentStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            countryContentStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -30).isActive = true
            countryContentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
            countryContentStackView.bottomAnchor.constraint(equalTo: separatorLineView.topAnchor, constant: -4).isActive = true
        }
        
        separatorLineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorLineView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        separatorLineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    }
    
    func applyFlagStyle(_ style: CountryFlagStyle) {
        
        NSLayoutConstraint.deactivate(flagImageView.constraints)
        layoutIfNeeded()
        
        switch style {
        case .corner:
            flagImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
            flagImageView.heightAnchor.constraint(equalToConstant: 26).isActive = true
            flagImageView.layer.cornerRadius = 4
            flagImageView.clipsToBounds = true
            flagImageView.contentMode = .scaleAspectFill
        case .circular:
            flagImageView.widthAnchor.constraint(equalToConstant: 34).isActive = true
            flagImageView.heightAnchor.constraint(equalToConstant: 34).isActive = true
            flagImageView.layer.cornerRadius = 34 / 2
            flagImageView.clipsToBounds = true
            flagImageView.contentMode = .scaleAspectFill
        default:
            flagImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
            flagImageView.heightAnchor.constraint(equalToConstant: 26).isActive = true
            flagImageView.contentMode = .scaleToFill
        }
    }
    
    func hideDialCode(_ state: Bool = true) {
        diallingCodeLabel.isHidden = state
    }

    func hideFlag(_ state: Bool = true) {
        countryFlagStackView.isHidden = state
    }
    
}


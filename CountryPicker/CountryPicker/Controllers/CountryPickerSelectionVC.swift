//
//  File.swift
//  
//
//  Created  on 01/07/21.
//

import UIKit

public class CountryPickerSectionVC: CountryPickerVC {

    private(set) var sections: [Character] = []
    private(set) var sectionCoutries =  [Character: [Country]]()
    private(set) var searchHeaderTitle: Character = "A"

    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSectionCountries()
        tableView.dataSource = self
        tableView.delegate = self
    }

    public override func viewDidAppear(_ animated: Bool) {
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
        scrollToPreviousCountryIfNeeded()
    }
    
    internal func scrollToPreviousCountryIfNeeded() {
        if let previousCountry = CountryManager.shared.lastCountrySelected {
           let previousCountryFirstCharacter = previousCountry.countryName.first!
           scrollToCountry(previousCountry, withSection: previousCountryFirstCharacter)
        }
    }
    
    @discardableResult
    override class func presentController(on viewController: UIViewController,
                                               handler:@escaping (_ country: Country) -> Void) -> CountryPickerSectionVC {
        let controller = CountryPickerSectionVC()
        controller.presentingVC = viewController
        controller.callBack = handler
        
        let navigationController = UINavigationController(rootViewController: controller)
        controller.presentingVC?.present(navigationController, animated: true, completion: nil)
        
        return controller
    }

}

internal extension CountryPickerSectionVC {
    
    func scrollToCountry(_ country: Country, withSection sectionTitle: Character, animated: Bool = false) {
        
        if applySearch { return }
        
        let countryMatchIndex = sectionCoutries[sectionTitle]?.firstIndex(where: { $0.countryCode == country.countryCode})
        
        let countrySectionKeyIndexes = sectionCoutries.keys.map { $0 }.sorted()
        let countryMatchSectionIndex = countrySectionKeyIndexes.firstIndex(of: sectionTitle)
        
        guard let row = countryMatchIndex, let section = countryMatchSectionIndex else {
            return
        }
        
        tableView.scrollToRow(at: IndexPath(row: row, section: section), at: .middle, animated: true)
    }
    
    func fetchSectionCountries() {
        
        sections = countries.map { String($0.countryName.prefix(1)).first! }
            .removeDuplicates()
            .sorted(by: <)
        for section in sections {
            let sectionCountries = countries.filter({ $0.countryName.first! == section }).removeDuplicates()
            sectionCoutries[section] = sectionCountries
        }
    }
}

// MARK: - TableView DataSource
extension CountryPickerSectionVC {

    func numberOfSections(in tableView: UITableView) -> Int {
        if applySearch {
            return 1
        }
        return  sections.count
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !applySearch else { return filterCountries.count }
        return numberOfRowFor(section: section)
    }

    func numberOfRowFor(section: Int) -> Int {
        let character = sections[section]
        return sectionCoutries[character]!.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !applySearch else {
            return String(searchHeaderTitle)
        }
    
        return sections[section].description
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
            let character = sections[indexPath.section]
            country = sectionCoutries[character]![indexPath.row]
        }

        if let alreadySelectedCountry = CountryManager.shared.lastCountrySelected {
            cell.checkMarkImageView.isHidden = country.countryCode == alreadySelectedCountry.countryCode ? false : true
        }

        cell.country = country
        setUpCellProperties(cell: cell)
        
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sections.map {String($0)}
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return sections.firstIndex(of: Character(title))!
    }
}

// MARK: - Override SearchBar Delegate
extension CountryPickerSectionVC {
    public override func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        super.searchBar(searchBar, textDidChange: searchText)
        if !searchText.isEmpty {
            searchHeaderTitle = searchText.first ?? "A"
        }
    }
}

// MARK: - TableViewDelegate
extension CountryPickerSectionVC {
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch applySearch {
        case true:
            let country = filterCountries[indexPath.row]
            triggerCallbackAndDismiss(with: country)
        case false:
            var country: Country?
            let character = sections[indexPath.section]
            country = sectionCoutries[character]![indexPath.row]
            guard let _country = country else {
                #if DEBUG
                  print("fail to get country")
                #endif
                return
            }
            triggerCallbackAndDismiss(with: _country)
        }
     }
    
    private func triggerCallbackAndDismiss(with country: Country) {
        callBack?(country)
        CountryManager.shared.lastCountrySelected = country
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
}

extension Array where Element: Equatable {
    func removeDuplicates() -> [Element] {
        var uniqueValues = [Element]()
        forEach {
            if !uniqueValues.contains($0) {
                uniqueValues.append($0)
            }
        }
        return uniqueValues
    }
}


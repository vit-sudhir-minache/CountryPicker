//
//  File.swift
//  
//
//  Created on 01/07/21.
//

import Foundation
import UIKit


public enum CountryFilterOption {
    case countryName
    case countryCode
    case countryDialCode
}

open class CountryManager {
    
    public var countries = [Country]()
    private var countriesFilePath: String? {
        #if SWIFT_PACKAGE
            let bundle = Bundle.module
        #else
            let bundle = Bundle(for: CountryManager.self)
        #endif
        
        let countriesPath = bundle.path(forResource: "CountryPickerVC.bundle/countries", ofType: "plist")
        return countriesPath
    }
    
    public static var shared: CountryManager = {
        let countryManager = CountryManager()
        do {
            try countryManager.loadCountries()
        } catch {
            #if DEBUG
              print(error.localizedDescription)
            #endif
        }
        return countryManager
    }()
    
    open var currentCountry: Country? {
        guard let countryCode = Locale.current.regionCode else {
            return nil
        }
        return Country(countryCode: countryCode)
    }
    
    
    internal var lastCountrySelected: Country?
    internal let defaultFilter: CountryFilterOption = .countryName
    internal var filters: Set<CountryFilterOption> = [.countryName]
        
    private init() {}
}


public extension CountryManager {
  
    func fetchCountries(fromURLPath path: URL) throws -> [Country] {
        guard let rawData = try? Data(contentsOf: path),
            let countryCodes = try? PropertyListSerialization.propertyList(from: rawData, format: nil) as? [String] else {
            throw "[CountryManager] ❌ Missing countries plist file from path: \(path)"
        }
        
        // Sort country list by `countryName`
        let sortedCountries = countryCodes.map { Country(countryCode: $0) }.sorted { $0.countryName < $1.countryName }
        
        #if DEBUG
        print("[CountryManager] ✅ Succefully prepared list of \(sortedCountries.count) countries")
        #endif
        
        return sortedCountries
    }
    
    func loadCountries() throws {
        let url = URL(fileURLWithPath: countriesFilePath ?? "")
        let fetchedCountries = try fetchCountries(fromURLPath: url)
        countries.removeAll()
        countries.append(contentsOf: fetchedCountries)
    }

    func allCountries(_ favoriteCountriesLocaleIdentifiers: [String]) -> [Country] {
        favoriteCountriesLocaleIdentifiers
            .compactMap { country(withCode: $0) } + countries
    }
    func resetLastSelectedCountry() {
        lastCountrySelected = nil
    }
}

public extension CountryManager {
  
    func country(withCode code: String) -> Country? {
         countries.first(where: { $0.countryCode.lowercased() == code.lowercased() })
    }
    
    func country(withName countryName: String) -> Country? {
         countries.first(where: { $0.countryName.lowercased() == countryName.lowercased() })
    }
    
    func country(withDigitCode dialCode: String) -> Country? {
         countries.first(where: { (country) -> Bool in
            guard let countryDialCode = country.digitCountrycode else {
                return false
            }
            
            var dialCode = dialCode
            
            if dialCode.contains("+"), let plusSignIndex = dialCode.firstIndex(of: "+") {
                dialCode.remove(at: plusSignIndex)
            }
            
            return dialCode == countryDialCode
        })
    }
}

public extension CountryManager {
    
    func addFilter(_ filter: CountryFilterOption) {
        filters.insert(filter)
    }
    func removeFilter(_ filter: CountryFilterOption) {
        filters.remove(filter)
    }
    func clearAllFilters() {
        filters.removeAll()
        filters.insert(defaultFilter) // Set default filter option
    }
}

// MARK: - Error Handling
extension String: Error {}
extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

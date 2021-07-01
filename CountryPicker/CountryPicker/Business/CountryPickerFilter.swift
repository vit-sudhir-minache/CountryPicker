//
//  File.swift
//  
//
//  Created  on 01/07/21.
//

import Foundation

struct CountryPickerFilter {
    let countries: [Country]
    let filterOptions: Set<CountryFilterOption>
    
    init(countries: [Country] = CountryManager.shared.countries, filterOptions: Set<CountryFilterOption> = CountryManager.shared.filters) {
        self.countries = countries
        self.filterOptions = filterOptions
    }
    
    func filterCountries(searchText: String) -> [Country] {
         countries.compactMap { (country) -> Country? in
            
            if  filterOptions.contains(.countryName),  country.countryName.capitalized.contains(searchText.capitalized) {
                return country
            }

            if filterOptions.contains(.countryCode),
               country.countryCode.capitalized.contains(searchText.capitalized) {
                return country
            }

            if filterOptions.contains(.countryDialCode),
                let digitCountryCode = country.digitCountrycode,
                digitCountryCode.contains(searchText) {
                return country
            }

            return nil
        }.removeDuplicates()
    }
}


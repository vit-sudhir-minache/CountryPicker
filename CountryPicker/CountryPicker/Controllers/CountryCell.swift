//
//  File.swift
//  
//
//  Created on 01/07/21.
//


import UIKit

class CountryCell: UITableViewCell {

    static let reuseIdentifier = String(describing: CountryCell.self)

    var flagStyle: CountryFlagStyle {
        return CountryFlagStyle.normal
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
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
        stackView.axis = .horizontal
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
        
        countryInfoStackView.addArrangedSubview(nameLabel)
        countryInfoStackView.addArrangedSubview(diallingCodeLabel)
        
        countryContentStackView.addArrangedSubview(countryFlagStackView)
        countryContentStackView.addArrangedSubview(countryInfoStackView)
        
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
            // Corner style
            flagImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
            flagImageView.heightAnchor.constraint(equalToConstant: 26).isActive = true
            flagImageView.layer.cornerRadius = 4
            flagImageView.clipsToBounds = true
            flagImageView.contentMode = .scaleAspectFill
        case .circular:
            // Circular style
            flagImageView.widthAnchor.constraint(equalToConstant: 34).isActive = true
            flagImageView.heightAnchor.constraint(equalToConstant: 34).isActive = true
            flagImageView.layer.cornerRadius = 34 / 2
            flagImageView.clipsToBounds = true
            flagImageView.contentMode = .scaleAspectFill
        default:
            // Apply default styling
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


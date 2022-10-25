//
//  FilterCell.swift
//  OpenCVCamera
//
//  Created by jhkim on 2022/10/25.
//

import UIKit
import RxSwift

class FilterCell: UICollectionViewCell {
    static let identifier = String(describing: FilterCell.self)
    
    private lazy var title = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        $0.text = "test @@@"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        contentView.backgroundColor = .systemBrown.withAlphaComponent(0.6)
        
        addSubviews([title])
        title.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
    
    func configure(data: String) {
        title.text = data
    }
}

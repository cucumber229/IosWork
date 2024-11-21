//
//  Gallery.swift
//  IosControl
//
//  Created by Артур Мавликаев on 21.11.2024.
//


import UIKit

class GalleryView: UIView {
    
    // MARK: - UI Elements
    
    let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Параллельно", "Последовательно"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 10
        let numberOfItemsPerRow: CGFloat = 3
        let totalSpacing = (numberOfItemsPerRow - 1) * spacing
        let itemWidth = (UIScreen.main.bounds.width - 40 - totalSpacing) / numberOfItemsPerRow // 40: отступы слева и справа
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .white
        return cv
    }()
    
    let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Начать вычисления", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Остановить", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true // Изначально скрыта
        return button
    }()
    
    let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "Результаты вычислений"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progress = 0.0
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
        setupSubviews()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    
    private func setupSubviews() {
        addSubview(segmentedControl)
        addSubview(collectionView)
        addSubview(startButton)
        addSubview(stopButton)
        addSubview(resultLabel)
        addSubview(progressView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            segmentedControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: 300),
            
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            collectionView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.6),
            
            startButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 10),
            startButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            
            stopButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 10),
            stopButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            stopButton.widthAnchor.constraint(equalToConstant: 100),
            stopButton.heightAnchor.constraint(equalToConstant: 40),
            
            resultLabel.topAnchor.constraint(equalTo: stopButton.bottomAnchor, constant: 10),
            resultLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            progressView.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 10),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
}

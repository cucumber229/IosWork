//
//  GalleryViewController.swift
//  IosControl
//
//  Created by Артур Мавликаев on 21.11.2024.


import UIKit

class GalleryViewController: UIViewController {
    
    // MARK: - Properties
    private var galleryView: GalleryView!
    private var images: [ImageModel] = []
    private var operationQueue: OperationQueue?
    private var processingMode: ProcessingMode = .parallel
    private var workItems: [DispatchWorkItem] = []
    
    private let imagesAccessQueue = DispatchQueue(label: "com.yourname.ImageAccessQueue", attributes: .concurrent)
    
    private let processedCountQueue = DispatchQueue(label: "com.yourapp.processedCountQueue")
    
    enum ProcessingMode {
        case parallel
        case sequential
    }
    
    // MARK: - Lifecycle Methods
    
    override func loadView() {
        galleryView = GalleryView()
        view = galleryView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupActions()
        loadImages()
    }
    
    deinit {
        operationQueue?.cancelAllOperations()
        for item in workItems {
            item.cancel()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupCollectionView() {
        galleryView.collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.identifier)
        galleryView.collectionView.dataSource = self
    }
    
    private func setupActions() {
        galleryView.segmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        galleryView.startButton.addTarget(self, action: #selector(startCalculations), for: .touchUpInside)
        galleryView.stopButton.addTarget(self, action: #selector(stopCalculations), for: .touchUpInside)
    }
    
    // MARK: - Load Images
    
    private func loadImages() {
        let imageNames = ["image 1", "image 2", "image 3", "image 4", "image 5",
                          "image 6", "image 7", "image 8", "image 9", "image 10"]
        
        images = imageNames.compactMap { name in
            if let img = UIImage(named: name) {
                return ImageModel(originalImage: img, processedImage: nil, isProcessing: false)
            }
            return nil
        }
        galleryView.collectionView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func modeChanged() {
        processingMode = galleryView.segmentedControl.selectedSegmentIndex == 0 ? .parallel : .sequential
        imagesAccessQueue.async(flags: .barrier) {
            for index in self.images.indices {
                self.images[index].processedImage = nil
                self.images[index].isProcessing = false
            }
        }
        DispatchQueue.main.async {
            self.galleryView.collectionView.reloadData()
            self.galleryView.progressView.progress = 0.0
            self.galleryView.resultLabel.text = "Результаты обработки"
        }
    }
    @objc private func startCalculations() {
        galleryView.startButton.isEnabled = false
        galleryView.stopButton.isHidden = false
        galleryView.resultLabel.text = "Начало обработки..."
        galleryView.progressView.progress = 0.0
        

        
        switch processingMode {
        case .parallel:
            processImagesInParallel()
        case .sequential:
            processImagesSequentially()
        }
    }
    
    @objc private func stopCalculations() {
        galleryView.startButton.isEnabled = true
        galleryView.stopButton.isHidden = true
        galleryView.resultLabel.text = "Обработка остановлена"
        
        switch processingMode {
        case .parallel:
            for item in workItems {
                item.cancel()
            }
            workItems.removeAll()
        case .sequential:
            operationQueue?.cancelAllOperations()
        }
    }
    
    // MARK: - Image Processing
    
    private func processImagesInParallel() {
        let totalImages = images.count
        var processedCount = 0
        workItems = []
        
        for index in 0..<totalImages {
            let currentIndex = index
            var workItem: DispatchWorkItem!
            workItem = DispatchWorkItem { [weak self, weak wItem = workItem] in
                guard let self = self else { return }
                
                if wItem?.isCancelled == true {
                    return
                }
                
                self.imagesAccessQueue.async(flags: .barrier) {
                    self.images[currentIndex].isProcessing = true
                }
                DispatchQueue.main.async {
                    self.galleryView.collectionView.reloadItems(at: [IndexPath(item: currentIndex, section: 0)])
                }
                
                let processedImage = self.applyRandomFilter(to: self.images[currentIndex].originalImage)
                
                if wItem?.isCancelled == true {
                    self.imagesAccessQueue.async(flags: .barrier) {
                        self.images[currentIndex].isProcessing = false
                    }
                    DispatchQueue.main.async {
                        self.galleryView.collectionView.reloadItems(at: [IndexPath(item: currentIndex, section: 0)])
                    }
                    return
                }
                
                self.imagesAccessQueue.async(flags: .barrier) {
                    self.images[currentIndex].processedImage = processedImage
                    self.images[currentIndex].isProcessing = false
                }
                DispatchQueue.main.async {
                    self.galleryView.collectionView.reloadItems(at: [IndexPath(item: currentIndex, section: 0)])
                }
                
                var currentProgress: Float = 0.0
                self.processedCountQueue.sync {
                    processedCount += 1
                    currentProgress = Float(processedCount) / Float(totalImages)
                }
                DispatchQueue.main.async {
                    self.galleryView.progressView.setProgress(currentProgress, animated: true)
                    self.galleryView.resultLabel.text = "Обработано \(processedCount) из \(totalImages)"
                    
                    if processedCount == totalImages {
                        self.galleryView.startButton.isEnabled = true
                        self.galleryView.stopButton.isHidden = true
                        self.galleryView.resultLabel.text = "Обработка завершена"
                    }
                }
            }
            workItems.append(workItem)
            DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        }
    }
    
    private func processImagesSequentially() {
        let totalImages = images.count
        var processedCount = 0
        operationQueue = OperationQueue()
        operationQueue?.maxConcurrentOperationCount = 1
        
        for index in 0..<totalImages {
            let currentIndex = index
            
            var operation: BlockOperation!
            operation = BlockOperation { [weak self, weak op = operation] in
                guard let self = self else { return }
                
                if op?.isCancelled == true {
                    return
                }
                
                self.imagesAccessQueue.async(flags: .barrier) {
                    self.images[currentIndex].isProcessing = true
                }
                OperationQueue.main.addOperation {
                    self.galleryView.collectionView.reloadItems(at: [IndexPath(item: currentIndex, section: 0)])
                }
                
                let processedImage = self.applyRandomFilter(to: self.images[currentIndex].originalImage)
                
                if op?.isCancelled == true {
                    self.imagesAccessQueue.async(flags: .barrier) {
                        self.images[currentIndex].isProcessing = false
                    }
                    OperationQueue.main.addOperation {
                        self.galleryView.collectionView.reloadItems(at: [IndexPath(item: currentIndex, section: 0)])
                    }
                    return
                }
                
                self.imagesAccessQueue.async(flags: .barrier) {
                    self.images[currentIndex].processedImage = processedImage
                    self.images[currentIndex].isProcessing = false
                }
                OperationQueue.main.addOperation {
                    self.galleryView.collectionView.reloadItems(at: [IndexPath(item: currentIndex, section: 0)])
                }
                
                processedCount += 1
                let progress = Float(processedCount) / Float(totalImages)
                OperationQueue.main.addOperation {
                    self.galleryView.progressView.setProgress(progress, animated: true)
                    self.galleryView.resultLabel.text = "Обработано \(processedCount) из \(totalImages)"
                    
                    if processedCount == totalImages {
                        self.galleryView.startButton.isEnabled = true
                        self.galleryView.stopButton.isHidden = true
                        self.galleryView.resultLabel.text = "Обработка завершена"
                    }
                }
            }
            
            operationQueue?.addOperation(operation)
        }
    }
    
    // MARK: - Apply Random Filter
    
    private let ciContext = CIContext()
    
    private func applyRandomFilter(to image: UIImage) -> UIImage {
        Thread.sleep(forTimeInterval: 2.0)
        
        let filterNames = ["CISepiaTone", "CIPhotoEffectNoir", "CIVignette", "CIBloom"]
        guard let filterName = filterNames.randomElement(),
              let ciImage = CIImage(image: image),
              let filter = CIFilter(name: filterName) else {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "Ошибка", message: "Не удалось создать фильтр для изображения.")
            }
            return image
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        if filterName == "CISepiaTone" || filterName == "CIVignette" {
            filter.setValue(1.0, forKey: kCIInputIntensityKey)
        }
        
        guard let outputImage = filter.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "Ошибка", message: "Не удалось применить фильтр к изображению.")
            }
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Show Alert
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension GalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.identifier, for: indexPath) as? ImageCollectionViewCell else {
            fatalError("Не удалось dequeued ImageCollectionViewCell")
        }
        
        var model: ImageModel?
        imagesAccessQueue.sync {
            model = self.images[indexPath.item]
        }
        
        if let model = model {
            cell.configure(with: model)
        }
        
        return cell
    }
}

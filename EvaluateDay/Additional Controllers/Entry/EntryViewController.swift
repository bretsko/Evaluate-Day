//
//  EntryViewController.swift
//  EvaluateDay
//
//  Created by Konstantin Tsistjakov on 02/02/2018.
//  Copyright © 2018 Konstantin Tsistjakov. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import Alamofire
import SwiftyJSON
import CoreLocation

class EntryViewController: UIViewController, ASTableDataSource, ASTableDelegate, SelectMapViewControllerDelegate, TimeBottomViewControllerDelegate, ASEditableTextNodeDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TextTopViewControllerDelegate {

    // MARK: - UI
    var tableNode: ASTableNode!
    var deleteButton: UIBarButtonItem!
    var closeButton: UIBarButtonItem!
    var shareButton: UIBarButtonItem!
    
    // MARK: - Variables
    var textValue: TextValue!
    var card: Card!
    
    var new: Bool = false
    
    private var lock = false
    
    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }
        
        // Delete button
        self.deleteButton = UIBarButtonItem(image: #imageLiteral(resourceName: "delete").resizedImage(newSize: CGSize(width: 22.0, height: 22.0)), style: .plain, target: self, action: #selector(self.deleteAction(sender:)))
        self.deleteButton.accessibilityLabel = Localizations.General.delete
        self.shareButton = UIBarButtonItem(image: #imageLiteral(resourceName: "share"), style: .plain, target: self, action: #selector(shareAction(sender:)))
        self.navigationItem.rightBarButtonItems = [self.deleteButton, self.shareButton]
        
        // Close button
        if self.navigationController?.viewControllers.first is EntryViewController {
            self.closeButton = UIBarButtonItem(image: #imageLiteral(resourceName: "close").resizedImage(newSize: CGSize(width: 22.0, height: 22.0)), style: .plain, target: self, action: #selector(closeButtonAction(sender:)))
            self.navigationItem.leftBarButtonItem = closeButton
        }
        
        // Lock
        if self.textValue.created.start.days(to: Date().start) > pastDaysLimit && !Store.current.isPro {
            self.lock = true
        }
        
        self.deleteButton.isEnabled = !self.lock
        
        // Set table node
        self.tableNode = ASTableNode(style: .plain)
        self.tableNode.dataSource = self
        self.tableNode.delegate = self
        self.tableNode.view.separatorStyle = .none
        self.tableNode.view.showsVerticalScrollIndicator = false
        self.tableNode.view.showsHorizontalScrollIndicator = false
        self.view.addSubnode(self.tableNode)
        self.tableNode.view.keyboardDismissMode = .interactive
        
        self.updateAppearance(animated: false)
        
        if self.textValue.location == nil {
            self.quickCheckIn(sender: ASButtonNode())
        }
        
        sendEvent(.openEntry, withProperties: ["new": self.new])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if self.view.traitCollection.userInterfaceIdiom == .pad && self.view.frame.size.width >= maxCollectionWidth {
            self.tableNode.frame = CGRect(x: self.view.frame.size.width / 2 - maxCollectionWidth / 2, y: 0.0, width: maxCollectionWidth, height: self.view.frame.size.height)
        } else {
            self.tableNode.frame = self.view.bounds
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func updateAppearance(animated: Bool) {
        super.updateAppearance(animated: animated)
        
        let duration: TimeInterval = animated ? 0.2 : 0
        UIView.animate(withDuration: duration) {
            // Backgrounds
            self.view.backgroundColor = UIColor.background
            self.tableNode.backgroundColor = UIColor.clear
            
            self.tableNode.reloadData()
        }
    }
    
    // MARK: - ASTableDataSource
    func numberOfSections(in tableNode: ASTableNode) -> Int {
        return 4
    }
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            // Date
            return 1
        case 2:
            // Locations
            if self.textValue.location != nil {
                return 2
            }
            return 1
        case 3:
            // Weather
            if self.textValue.weather != nil {
                return 1
            }
            return 0
        default:
            return 0
        }
    }
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        switch indexPath.section {
        case 0:
            let text = self.textValue.text
            let photo = self.textValue.photos.first?.image
            return {
                let node = JournalEntryNode(text: text, metadata: [], photo: photo, editMode: !self.lock)
                if node.selectImageButton != nil {
                    node.selectImageButton.addTarget(self, action: #selector(self.photoAction(sender:)), forControlEvents: .touchUpInside)
                }
                if node.cameraButton != nil {
                    node.cameraButton.addTarget(self, action: #selector(self.cameraAction(sender:)), forControlEvents: .touchUpInside)
                }
                if node.deleteImageButton != nil {
                    node.deleteImageButton.addTarget(self, action: #selector(self.deletePhotoAction(sender:)), forControlEvents: .touchUpInside)
                }
                if node.editTextButton != nil {
                    node.editTextButton.addTarget(self, action: #selector(self.editTextButtonAction(sender:)), forControlEvents: .touchUpInside)
                }
                if node.imageButton != nil {
                    node.imageButton.addTarget(self, action: #selector(self.openPhoto(sender:)), forControlEvents: .touchUpInside)
                }
                node.selectionStyle = .none
                return node
            }
        case 1:
            let date = self.textValue.created
            return {
                let node = DateNode(date: date)
                return node
            }
        case 2:
            if let loc = self.textValue.location {
                if indexPath.row == 1 {
                    let street = loc.streetString
                    let otherAdress = loc.otherAddressString
                    let coordinates = loc.coordinatesString
                    return {
                        let node = CheckInDataEvaluateNode(street: street, otherAddress: otherAdress, coordinates: coordinates)
                        node.accessibilityTraits = UIAccessibilityTraitNone
                        node.selectionStyle = .none
                        node.leftInset = 30.0
                        return node
                    }
                }
            }
            
            if Permissions.defaults.locationStatus == .authorizedWhenInUse {
                let date = self.textValue.created
                return {
                    let node = CheckInActionNode(date: date)
                    if !self.lock {
                        node.mapButton.addTarget(self, action: #selector(self.openMap(sender:)), forControlEvents: .touchUpInside)
                        node.checkInButton.addTarget(self, action: #selector(self.quickCheckIn(sender:)), forControlEvents: .touchUpInside)
                    }
                    node.selectionStyle = .none
                    node.currentDate.attributedText = NSAttributedString(string: "")
                    return node
                }
            } else {
                let date = self.textValue.created
                return {
                    let node = CheckInPermissionNode(date: date)
                    if !self.lock {
                        node.mapButton.addTarget(self, action: #selector(self.openMap(sender:)), forControlEvents: .touchUpInside)
                        node.permissionButton.addTarget(self, action: #selector(self.allowLocation(sender:)), forControlEvents: .touchUpInside)
                    }
                    node.leftInset = 30.0
                    node.selectionStyle = .none
                    node.currentDate.attributedText = NSAttributedString(string: "")
                    return node
                }
            }
        case 3:
            let w = self.textValue.weather!
            var icon = UIImage(named: w.icon)
            var data = [String]()
            var temperature = "\(String(format: "%.0f", w.temperarure)) ℃"
            var apparentTemperature = "\(String(format: "%.0f", w.apparentTemperature)) ℃"
            if !Database.manager.application.settings.celsius {
                temperature = "\(String(format: "%.0f", (w.temperarure * (9/5) + 32))) ℉"
                apparentTemperature = "\(String(format: "%.0f", (w.apparentTemperature * (9/5) + 32))) ℉"
            }
            data.append(temperature)
            data.append(apparentTemperature)
        
            let humidity = String(format: "%.0f", w.humidity * 100) + " %"
            data.append(humidity)
            
            let pressure = String(format: "%.1f", w.pressure) + " mBar"
            data.append(pressure)
            
            var windSpeed = String(format: "%.1f", w.windSpeed) + " m/s"
            if !Locale.current.usesMetricSystem {
                windSpeed = String(format: "%.1f", w.windSpeed * (25/11)) + " mi/hr"
            }
            data.append(windSpeed)
            
            let cc = String(format: "%.1f", w.cloudCover * 100) + " %"
            data.append(cc)
            
            var text = Localizations.Evaluate.Journal.Entry.weather(temperature, apparentTemperature, humidity, pressure, windSpeed, cc)
            
            if w.pressure == 0.0 && w.humidity == 0.0 {
                data.removeAll()
                text = Localizations.Evaluate.Weather.unknown
                icon = #imageLiteral(resourceName: "clear-day")
            }
            return {
                let node = WeatherNode(icon: icon, text: text, data: data)
                node.selectionStyle = .none
                return node
            }
        default:
            return {
                return ASCellNode()
            }
        }
    }
    
    // MARK: - ASTableDelegate
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        if self.lock {
            return
        }
        
        if indexPath.section == 1 {
            let controller = TimeBottomViewController()
            controller.pickerMode = .dateAndTime
            controller.date = self.textValue.created
            controller.maximumDate = Date()
            controller.delegate = self
            controller.closeByTap = true
            
            if !Store.current.isPro {
                var components = DateComponents()
                components.day = -pastDaysLimit
                controller.minumumDate = Calendar.current.date(byAdding: components, to: Date().start)
            }
            
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: - TimeBottomViewControllerDelegate
    func didSelectTime(inDate date: Date) {
        self.setNewDate(date: date)
    }
    
    // MARK: - SelectMapViewControllerDelegate
    func selectLocation(controller: SelectMapViewController, locationValue value: LocationValue?) {
        guard let location = self.textValue.location, let nvalue = value else {
            if value == nil || value?.realm == nil {
                return
            }
            value!.owner = self.textValue.id
            try! Database.manager.data.write {
                Database.manager.data.add(value!)
            }
            
            return
        }
        
        let locationValue = LocationValue()
        locationValue.id = location.id
        locationValue.owner = location.owner
        locationValue.created = location.created
        locationValue.edited = Date()
        locationValue.location = nvalue.location
        
        locationValue.city = nvalue.city
        locationValue.country = nvalue.country
        locationValue.state = nvalue.state
        locationValue.street = nvalue.street
        
        try! Database.manager.data.write {
            Database.manager.data.add(locationValue, update: true)
        }
        
        self.tableNode.reloadSections(IndexSet(integer: 2), with: .automatic)
        self.updateWeatherInformation()
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func deleteLocation(controller: SelectMapViewController, locationValue value: LocationValue?) {
        guard let location = self.textValue.location else {
            return
        }
        
        if location.realm == nil {
            return
        }
        
        try! Database.manager.data.write {
            location.isDeleted = true
        }
        
        self.tableNode.reloadSections(IndexSet(integer: 2), with: .automatic)
        
        guard let weather = self.textValue.weather else {
            return
        }
        
        try! Database.manager.data.write {
            weather.isDeleted = true
        }
        
        self.tableNode.reloadSections(IndexSet(integer: 3), with: .automatic)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            var mainAsset: PHAsset?
            if #available(iOS 11.0, *) {
                if let asset = info[UIImagePickerControllerPHAsset] as? PHAsset {
                    mainAsset = asset
                }
            } else {
                // Fallback on earlier versions
                if let assetURL = info[UIImagePickerControllerReferenceURL] as? String {
                    let url = URL(fileURLWithPath: assetURL)
                    if let asset = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil).firstObject {
                        mainAsset = asset
                    }
                }
            }
            
            if let photo = self.textValue.photos.first {
                photo.image = image
                try! Database.manager.data.write {
                    photo.edited = Date()
                }
            } else {
                let photo = PhotoValue()
                photo.owner = self.textValue.id
                photo.image = image
                
                try! Database.manager.data.write {
                    Database.manager.data.add(photo)
                }
            }
            
            self.tableNode.reloadSections(IndexSet(integer: 0), with: .automatic)
            
            if mainAsset != nil {
                let date = mainAsset!.creationDate
                let loc = mainAsset!.location
                
                if date == nil {
                    return
                } else {
                    if date!.days(to: Date()) < 1 {
                        return
                    }
                }
                
                if loc != nil {
                    if let currentLocation = Permissions.defaults.currentLocation.value {
                        if loc!.distance(from: currentLocation) < 500 {
                            return
                        }
                    }
                }
                
                var partTitle = ""
                var message = ""
                if date != nil {
                    partTitle = Localizations.Evaluate.Journal.Entry.Photo.date
                    message = DateFormatter.localizedString(from: date!, dateStyle: .medium, timeStyle: .short)
                }
                if partTitle != "" {
                    partTitle += " \(Localizations.General.and) "
                }
                if loc != nil {
                    partTitle += Localizations.Evaluate.Journal.Entry.Photo.location
                }
                
                let title = Localizations.Evaluate.Journal.Entry.Photo.question(partTitle)
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                
                let cancelAction = UIAlertAction(title: Localizations.General.cancel, style: .cancel, handler: nil)
                let dateAction = UIAlertAction(title: Localizations.Evaluate.Journal.Entry.Photo.date, style: .default, handler: { (_) in
                    
                    self.setNewDate(date: date!)
                })
                let locationAction = UIAlertAction(title: Localizations.Evaluate.Journal.Entry.Photo.location, style: .default, handler: { (_) in
                    self.setNewLocation(location: loc!)
                })
                let bothAction = UIAlertAction(title: Localizations.Evaluate.Journal.Entry.Photo.useBoth, style: .default, handler: { (_) in
                    
                    self.setNewLocation(location: loc!)
                    self.setNewDate(date: date!)
                })
                
                if date != nil {
                    alert.addAction(dateAction)
                }
                if loc != nil {
                    alert.addAction(locationAction)
                }
                if date != nil && loc != nil {
                    alert.addAction(bothAction)
                }
                alert.addAction(cancelAction)
                
                alert.view.tintColor = Themes.manager.evaluateStyle.actionSheetTintColor
                alert.view.layoutIfNeeded()
                
                if loc == nil {
                    self.present(alert, animated: true) {
                        alert.view.tintColor = Themes.manager.evaluateStyle.actionSheetTintColor
                    }
                } else {
                    CLGeocoder().reverseGeocodeLocation(loc!, completionHandler: { (places, _) in
                        if let place = places?.first {
                            message += "\n"
                            if place.name != nil {
                                message += place.name!
                            }
                            if place.locality != nil {
                                message += ", " + place.locality!
                            }
                            if place.administrativeArea != nil {
                                message += ", " + place.administrativeArea!
                            }
                            if place.country != nil {
                                message += ", " + place.country!
                            }
                            alert.message = message
                            self.present(alert, animated: true) {
                                alert.view.tintColor = Themes.manager.evaluateStyle.actionSheetTintColor
                            }
                        }
                    })
                }
            } else {
                if Database.manager.application.settings.cameraRoll {
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                }
            }
        }
    }
    
    // MARK: - TextTopViewControllerDelegate
    func textTopController(controller: TextTopViewController, willCloseWith text: String, forProperty property: String) {
        try! Database.manager.data.write {
            self.textValue.text = text
        }
        
        self.tableNode.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    // MARK: - Actions
    func updateWeatherInformation() {
        guard let location =  self.textValue.location else {
            return
        }
        
        let url = "\(weatherLink)\(location.latitude),\(location.longitude),\(Int(self.textValue.created.timeIntervalSince1970))"
        let urlParams = ["units": "si", "exclude": "[hourly, daily, flags]"]
        
        Alamofire.request(url, method: .get, parameters: urlParams).responseJSON { (response) in
            if response.error != nil {
                print("Weather responce error - \(response.error!.localizedDescription)")
                if self.textValue.weather == nil {
                    let weatherValue = WeatherValue()
                    weatherValue.owner = self.textValue.id
                    weatherValue.edited = Date()
                    
                    weatherValue.latitude = location.latitude
                    weatherValue.longitude = location.longitude
                    try! Database.manager.data.write {
                        Database.manager.data.add(weatherValue, update: true)
                    }
                    
                    self.tableNode.reloadSections(IndexSet(integer: 3), with: .automatic)
                }
                
                return
            }
            
            let json = JSON(response.data!)["currently"]
            
            let id: String
            let created: Date
            if let weather = self.textValue.weather {
                id = weather.id
                created = weather.created
            } else {
                id = UUID.id
                created = Date()
            }
            
            let weatherValue = WeatherValue()
            weatherValue.id = id
            weatherValue.created = created
            weatherValue.owner = self.textValue.id
            weatherValue.edited = Date()
            
            weatherValue.latitude = location.latitude
            weatherValue.longitude = location.longitude
            weatherValue.temperarure = json[WeatherKey.temperature].doubleValue
            weatherValue.apparentTemperature = json[WeatherKey.apparentTemperature].doubleValue
            weatherValue.summary = json[WeatherKey.summary].stringValue
            weatherValue.icon = json[WeatherKey.icon].stringValue
            weatherValue.humidity = json[WeatherKey.humidity].doubleValue
            weatherValue.pressure = json[WeatherKey.pressure].doubleValue
            weatherValue.windSpeed = json[WeatherKey.windSpeed].doubleValue
            weatherValue.cloudCover = json[WeatherKey.cloudCover].doubleValue
            
            try! Database.manager.data.write {
                Database.manager.data.add(weatherValue, update: true)
            }
            
            self.tableNode.reloadSections(IndexSet(integer: 3), with: .automatic)
            
        }
    }
    
    @objc func cameraAction(sender: ASButtonNode) {
        if Permissions.defaults.cameraStatus != .authorized {
            Permissions.defaults.cameraAutorize(completion: {
                self.openPhotoPicker(withType: .camera)
            })
            return
        }
        self.openPhotoPicker(withType: .camera)
    }
    
    @objc func photoAction(sender: ASButtonNode) {
        if Permissions.defaults.photoStatus != .authorized {
            Permissions.defaults.photoAutorize(completion: {
                self.openPhotoPicker(withType: .photoLibrary)
            })
            return
        }
        
        self.openPhotoPicker(withType: .photoLibrary)
    }
    
    @objc func openPhoto(sender: ASButtonNode) {
        if let photo = Database.manager.data.objects(PhotoValue.self).filter("owner=%@", self.textValue.id).first {
            let controller = UIStoryboard(name: Storyboards.photo.rawValue, bundle: nil).instantiateInitialViewController() as! PhotoViewController
            controller.photoValue = photo
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    @objc func deletePhotoAction(sender: ASButtonNode) {
        if let photo = self.textValue.photos.first {
            try! Database.manager.data.write {
                photo.isDeleted = true
            }
            
            self.tableNode.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
    
    @objc func editTextButtonAction(sender: ASButtonNode) {
        let controller = TextTopViewController()
        controller.delegate = self
        controller.textView.text = self.textValue.text
        self.present(controller, animated: true, completion: nil)
    }
    
    private func openPhotoPicker(withType type: UIImagePickerControllerSourceType) {
        let photoController = UIImagePickerController()
        photoController.sourceType = type
        photoController.delegate = self
        self.present(photoController, animated: true, completion: nil)
    }
    
    @objc func allowLocation(sender: ASButtonNode) {
        Permissions.defaults.locationAuthorize {
            self.tableNode.reloadSections(IndexSet(integer: 2), with: .automatic)
        }
    }
    
    @objc func openMap(sender: ASButtonNode) {
        let controller = UIStoryboard(name: Storyboards.selectMap.rawValue, bundle: nil).instantiateInitialViewController() as! SelectMapViewController
        controller.delegate = self
        self.present(controller, animated: true, completion: nil)
    }
    
    @objc func quickCheckIn(sender: ASButtonNode) {
        guard let currentLocation = Permissions.defaults.currentLocation.value else {
            return
        }
        
        self.setNewLocation(location: currentLocation)
    }
    
    @objc func deleteAction(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: Localizations.General.sureQuestion, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: Localizations.General.cancel, style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: Localizations.General.delete, style: .destructive) { (_) in
            if self.textValue.location != nil {
                try! Database.manager.data.write {
                    self.textValue.location!.isDeleted = true
                }
            }
            if self.textValue.weather != nil {
                try! Database.manager.data.write {
                    self.textValue.weather!.isDeleted = true
                }
            }
            
            try! Database.manager.data.write {
                for p in self.textValue.photos {
                    p.isDeleted = true
                }
                
                self.textValue.isDeleted = true
            }
            if self.navigationController?.viewControllers.first is EntryViewController {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        if self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            alert.popoverPresentationController?.barButtonItem = self.deleteButton
            alert.popoverPresentationController?.sourceView = self.view
        }
        
        alert.view.tintColor = Themes.manager.evaluateStyle.actionSheetTintColor
        alert.view.layoutIfNeeded()
        self.present(alert, animated: true) {
            alert.view.tintColor = Themes.manager.evaluateStyle.actionSheetTintColor
        }
    }
    
    @objc func closeButtonAction(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func shareAction(sender: UIBarButtonItem) {
        var viewImages = [UIImageView]()
        
        // Main entry node
        if let node = self.tableNode.nodeForRow(at: IndexPath(row: 0, section: 0)) as? JournalEntryNode {
            if node.deleteImageButton != nil {
                node.deleteImageButton.alpha = 0.0
            }
            if node.cameraButton != nil {
                node.cameraButton.alpha = 0.0
            }
            if node.selectImageButton != nil {
                node.selectImageButton.alpha = 0.0
            }
            
            if let nodeImage = node.view.snapshot {
                viewImages.append(UIImageView(image: nodeImage))
            }
            
            if node.deleteImageButton != nil {
                node.deleteImageButton.alpha = 1.0
            }
            if node.cameraButton != nil {
                node.cameraButton.alpha = 1.0
            }
            if node.selectImageButton != nil {
                node.selectImageButton.alpha = 1.0
            }
        }
        // Date Node
        if let node = self.tableNode.nodeForRow(at: IndexPath(row: 0, section: 1)) {
            if let nodeImage = node.view.snapshot {
                viewImages.append(UIImageView(image: nodeImage))
            }
        }
        // Location Node
        if let node = self.tableNode.nodeForRow(at: IndexPath(row: 1, section: 2)) {
            if let nodeImage = node.view.snapshot {
                viewImages.append(UIImageView(image: nodeImage))
            }
        }
        // Weather Node
        if let node = self.tableNode.nodeForRow(at: IndexPath(row: 0, section: 3)) {
            if let nodeImage = node.view.snapshot {
                viewImages.append(UIImageView(image: nodeImage))
            }
        }
        
        let imageBackgroundView = UIView()
        imageBackgroundView.backgroundColor = Themes.manager.analyticalStyle.background
        
        let stack = UIStackView(arrangedSubviews: viewImages)
        stack.axis = .vertical
        
        imageBackgroundView.addSubview(stack)
        stack.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(imageBackgroundView)
        imageBackgroundView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        imageBackgroundView.layoutIfNeeded()
        let imageBackgroundViewImage = imageBackgroundView.snapshot!
        imageBackgroundView.removeFromSuperview()
        
        let sv = ShareView(image: imageBackgroundViewImage)
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(sv)
        sv.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
        }
        sv.layoutIfNeeded()
        let im = sv.snapshot
        sv.removeFromSuperview()
        
        let shareContrroller = UIStoryboard(name: Storyboards.share.rawValue, bundle: nil).instantiateInitialViewController() as! ShareViewController
        shareContrroller.image = im
        shareContrroller.canonicalIdentifier = "entryShare"
        shareContrroller.channel = "Journal"
        shareContrroller.shareHandler = { () in
            sendEvent(.shareFromEvaluateDay, withProperties: ["type": self.card.type.string])
        }
        
        self.present(shareContrroller, animated: true, completion: nil)
    }
    
    func setNewLocation(location: CLLocation) {
        let id: String
        let created: Date
        if let loc = self.textValue.location {
            id = loc.id
            created = loc.created
        } else {
            id = UUID.id
            created = Date()
        }
        
        let locationValue = LocationValue()
        locationValue.id = id
        locationValue.created = created
        locationValue.owner = self.textValue.id
        locationValue.edited = Date()
        
        locationValue.location = location
        locationValue.locationInformation { (street, city, state, country) in
            locationValue.street = street
            locationValue.city = city
            locationValue.state = state
            locationValue.country = country
            
            try! Database.manager.data.write {
                Database.manager.data.add(locationValue, update: true)
            }
            
            self.tableNode.reloadSections(IndexSet(integer: 2), with: .automatic)
            self.updateWeatherInformation()
        }
    }
    
    func setNewDate(date: Date) {
        try! Database.manager.data.write {
            self.textValue.created = date
            self.textValue.edited = Date()
        }
        
        self.tableNode.reloadSections(IndexSet(integer: 1), with: .automatic)
        self.updateWeatherInformation()
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            print("save went wrong - \(error!.localizedDescription)")
            return
        }
        
        print("Save image to camera roll ok")
    }
}

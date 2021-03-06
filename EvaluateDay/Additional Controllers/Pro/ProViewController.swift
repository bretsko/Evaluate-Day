//
//  ProViewController.swift
//  EvaluateDay
//
//  Created by Konstantin Tsistjakov on 19/01/2019.
//  Copyright © 2019 Konstantin Tsistjakov. All rights reserved.
//

import UIKit
import SafariServices
import StoreKit

class ProViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UI
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Variables
    private let subscribeToProCell = "subscribeToProCell"
    private let subscriptionReviewCell = "subscriptionReviewCell"
    
    private let showDetailSegue = "showDetailSegue"

    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set navigation item
        self.navigationItem.title = Localizations.Settings.Pro.title
        
        Feedback.player.play(sound: SoundType.openPro, hapticFeedback: true, impact: false, feedbackType: nil)
        if Store.current.isPro {
            sendEvent(Analytics.openProReview, withProperties: nil)
        } else {
            sendEvent(Analytics.openPro, withProperties: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateAppearance(animated: false)
    }
    
    override func updateAppearance(animated: Bool) {
        super.updateAppearance(animated: animated)
        
        let duration: TimeInterval = animated ? 0.2 : 0
        UIView.animate(withDuration: duration) {
            //set NavigationBar
            self.navigationController?.navigationBar.barTintColor = UIColor.background
            self.navigationController?.navigationBar.isTranslucent = false
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.tintColor = UIColor.main
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.text]
            if #available(iOS 11.0, *) {
                self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.text]
            }
            
            // Backgrounds
            self.view.backgroundColor = UIColor.background
            
            // TableView
            self.tableView.backgroundColor = UIColor.background
        }
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if Store.current.isPro {
            let cell = tableView.dequeueReusableCell(withIdentifier: subscriptionReviewCell, for: indexPath) as! SubscriptionReviewCell
            cell.privacyButton.addTarget(self, action: #selector(self.openPrivacy(sender:)), for: .touchUpInside)
            cell.eulaButton.addTarget(self, action: #selector(self.openEULA(sender:)), for: .touchUpInside)
            cell.manageButton.addTarget(self, action: #selector(self.manageSubscriptions(sender:)), for: .touchUpInside)
            
            let selectedView = UIView()
            selectedView.backgroundColor = UIColor.tint
            
            cell.selectedBackgroundView = selectedView
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: subscribeToProCell, for: indexPath) as! SubscriptionBuyCell
        cell.privacyButton.addTarget(self, action: #selector(self.openPrivacy(sender:)), for: .touchUpInside)
        cell.eulaButton.addTarget(self, action: #selector(self.openEULA(sender:)), for: .touchUpInside)
        cell.continueButton.addTarget(self, action: #selector(self.continuePurchaseAction(sender:)), for: .touchUpInside)
        cell.restoreButton.addTarget(self, action: #selector(self.restorePurchasesAction(sender:)), for: .touchUpInside)
        cell.oneTimeButton.addTarget(self, action: #selector(self.oneTimePurchaseAction(sender:)), for: .touchUpInside)
        cell.viewMoreButton.addTarget(self, action: #selector(self.readMoreAction(sender:)), for: .touchUpInside)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if Store.current.isPro {
            let controller = UIStoryboard(name: Storyboards.web.rawValue, bundle: nil).instantiateInitialViewController() as! UINavigationController
            let topController = controller.topViewController as! WebViewController
            if Store.current.subscriptionID == Store.current.monthlyProductID {
                topController.html = Bundle.main.path(forResource: "monthly", ofType: "html")
                self.present(controller, animated: true, completion: nil)
            } else if Store.current.subscriptionID == Store.current.annuallyProductID {
                topController.html = Bundle.main.path(forResource: "annualy", ofType: "html")
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Actions
    @objc func openPrivacy(sender: UIButton) {
        let safari = SFSafariViewController(url: URL(string: privacyURLString)!)
        self.present(safari, animated: true, completion: nil)
    }
    
    @objc func openEULA(sender: UIButton) {
        let safari = SFSafariViewController(url: URL(string: eulaURLString)!)
        self.present(safari, animated: true, completion: nil)
    }
    
    @objc func readMoreAction(sender: UIButton) {
        self.performSegue(withIdentifier: showDetailSegue, sender: self)
    }
    
    @objc func continuePurchaseAction(sender: UIButton) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SubscriptionBuyCell {
            self.showLoadView()
            let product = cell.isTopSelected ? Store.current.annualy : Store.current.mouthly
            sendEvent(Analytics.startPay, withProperties: ["product": product?.productIdentifier ?? "WTF"])
            Feedback.player.notify(type: UINotificationFeedbackGenerator.FeedbackType.success)
            Store.current.payment(product: product) { (transaction, error) in
                if transaction != nil {
                    if transaction!.transactionState == SKPaymentTransactionState.purchasing || transaction!.transactionState == SKPaymentTransactionState.purchased {
                        sendEvent(Analytics.donePay, withProperties: ["product": product?.productIdentifier ?? "WTF"])
                    }
                }
                self.tableView.reloadData()
                self.hideLoadView()
            }
        }
    }
    
    @objc func restorePurchasesAction(sender: UIButton) {
        self.showLoadView()
        Feedback.player.notify(type: UINotificationFeedbackGenerator.FeedbackType.success)
        Store.current.restore { (transactions, error) in
            self.tableView.reloadData()
            self.hideLoadView()
        }
    }
    
    @objc func oneTimePurchaseAction(sender: UIButton) {
        self.showLoadView()
        sendEvent(Analytics.startPay, withProperties: ["product": Store.current.lifetime.productIdentifier])
        Feedback.player.notify(type: UINotificationFeedbackGenerator.FeedbackType.success)
        Store.current.payment(product: Store.current.lifetime) { (transaction, error) in
            if transaction != nil {
                if transaction!.transactionState == SKPaymentTransactionState.purchasing || transaction!.transactionState == SKPaymentTransactionState.purchased {
                    sendEvent(Analytics.donePay, withProperties: ["product": Store.current.lifetime.productIdentifier])
                }
            }
            self.hideLoadView()
        }
    }
    
    @objc func manageSubscriptions(sender: UIButton) {
        if let url = URL(string: subscriptionManageURL) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
    }
    
    // MARK: - Private Actions
    private var loadCoverView: UIView!
    private var loadIndicatorView: UIActivityIndicatorView!
    private func showLoadView() {
        self.loadCoverView = UIView()
        self.loadCoverView.backgroundColor = UIColor.background
        self.loadCoverView.alpha = 0.0
        
        self.loadIndicatorView = UIActivityIndicatorView(style: .gray)
        self.loadIndicatorView.alpha = 0.0
        self.loadIndicatorView.startAnimating()
        
        self.view.addSubview(self.loadCoverView)
        self.loadCoverView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        self.view.addSubview(self.loadIndicatorView)
        self.loadIndicatorView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        UIView.animate(withDuration: 0.3) {
            self.loadCoverView.alpha = 0.6
            self.loadIndicatorView.alpha = 1.0
        }
    }
    
    private func hideLoadView() {
        
        self.loadIndicatorView.stopAnimating()
        UIView.animate(withDuration: 0.3) {
            self.loadCoverView.alpha = 0.0
            self.loadIndicatorView.alpha = 0.0
        }
        
        self.loadCoverView.removeFromSuperview()
        self.loadIndicatorView.removeFromSuperview()
    }
}

// Helper function inserted by Swift 4.2 migrator
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

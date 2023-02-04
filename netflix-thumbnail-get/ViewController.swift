//
//  ViewController.swift
//  netflix-thumbnail-get
//
//  Created by JotaroSugiyama on 2023/02/04.
//

import UIKit
import Alamofire
import SwiftSoup

class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc func textFieldDidChange() {
        guard let url = textField.text, !url.isEmpty else {
            return
        }
        
        if !url.contains("www.netflix.com") {
            return
        }
        
        activityIndicator.startAnimating()
        getThumbnailImage(url: url) { (success) in
            self.activityIndicator.stopAnimating()
            if (success != nil) {
                self.imageView.image = success
            }
        }
    }
    
    func getThumbnailImage(url: String, completion: @escaping (_ image: UIImage?) -> Void) {
        AF.request(url).responseString { response in
            guard let html = response.value else {
                completion(nil)
                return
            }
            
            do {
                let doc = try SwiftSoup.parse(html)
                let elements = try doc.select("meta[property='og:image']")
                
                guard let firstElement = elements.first() else {
                    completion(nil)
                    return
                }
                
                guard let imageUrl = try? firstElement.attr("content") else {
                    completion(nil)
                    return
                }
                
                AF.request(imageUrl).responseData { response in
                    guard let data = response.value else {
                        completion(nil)
                        return
                    }
                    
                    completion(UIImage(data: data))
                }
            } catch {
                completion(nil)
            }
        }
    }
    
}


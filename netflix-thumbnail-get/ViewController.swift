import UIKit
import Alamofire
import SwiftSoup

class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(saveImage))
        imageView.addGestureRecognizer(tapGesture)
    }
    
    @objc func textFieldDidChange() {
        guard let url = textField.text, !url.isEmpty else {
            return
        }
        
        let netflixUrl = url.replacingOccurrences(of: "\\?.*", with: "", options: .regularExpression)
        
        activityIndicator.startAnimating()
        getMovieInfo(url: netflixUrl) { (success, title) in
            self.activityIndicator.stopAnimating()
            if (success != nil) {
                self.imageView.image = success
                self.titleLabel.text = title
            }
        }
    }
    
    @objc func saveImage(_ sender: UITapGestureRecognizer) {
        guard let image = imageView.image else {
            return
        }
        
        let alert = UIAlertController(title: "保存", message: "画像を保存しますか？", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.saveImageCompletion), nil)
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }

    @objc func saveImageCompletion(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print(error)
            return
        }
        
        let alert = UIAlertController(title: "保存が完了しました", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    
    func getMovieInfo(url: String, completion: @escaping (_ image: UIImage?, _ title: String?) -> Void) {
        AF.request(url).responseString { response in
            guard let html = response.value else {
                completion(nil, nil)
                return
            }
            
            do {
                let doc = try SwiftSoup.parse(html)
                let elementsImage = try doc.select("meta[property='og:image']")
                let elementsTitle = try doc.select("meta[property='og:title']")
                
                guard let firstElementImage = elementsImage.first() else {
                    completion(nil, nil)
                    return
                }
                
                guard let firstElementTitle = elementsTitle.first() else {
                    completion(nil, nil)
                    return
                }
                
                guard let imageUrl = try? firstElementImage.attr("content"), var title = try? firstElementTitle.attr("content") else {
                    completion(nil, nil)
                    return
                }
                
                title = title.replacingOccurrences(of: " \\| Netflix.*", with: "", options: .regularExpression)
                
                AF.request(imageUrl).responseData { response in
                    guard let data = response.value else {
                        completion(nil, nil)
                        return
                    }
                    
                    completion(UIImage(data: data), title)
                }
            } catch {
                completion(nil, nil)
            }
        }
    }
    
}

//
//  Extensions.swift
//  Task 2
//
//  Created by Mohamed Attar on 11/10/2021.
//

import UIKit


extension UIImageView {
    // Download an image from URL and saving it into cache with its URL as the key to grab it from the cache whenever it is needed.
    func downloadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        let cacheKey = NSString(string: urlString)
        
        if let image = ModelManager.shared.cache.object(forKey: cacheKey) {
            self.image = image
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {return}
            if error != nil {
                DispatchQueue.main.async {
                    self.image = UIImage(named: "placeholder")
                }
                
                return
            }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.image = UIImage(named: "placeholder")
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.image = UIImage(named: "placeholder")
                }
                return
            }
            guard let image = UIImage(data: data) else { return }
            ModelManager.shared.cache.setObject(image, forKey: cacheKey)
            DispatchQueue.main.async {
                self.image = image
            }
        }
        task.resume()
    }
}

extension UIViewController {
    // Presenting an UIAlertController when there is an error.
    func presentError(title: String, message: String) {
        DispatchQueue.main.async {
            let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertVC, animated: true)
        }
    }
}

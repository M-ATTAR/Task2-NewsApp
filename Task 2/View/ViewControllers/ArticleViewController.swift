//
//  ArticleViewController.swift
//  Task 2
//
//  Created by Mohamed Attar on 11/10/2021.
//

import UIKit

class ArticleViewController: UIViewController {

    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var autherLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var gradiantView: UIView!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var descLabel: UILabel!
    
    var article: Article?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setting up all the labels.
        sourceLabel.text = article?.source?.name
        autherLabel.text = "By: \(article?.author ?? "N/A")"
        titleLabel.text = article?.title
        setImage(imageURL: article?.urlToImage)
        dateLabel.text = article?.publishedAt?.convertToDMY()
        descLabel.text = article?.description
        contentTextView.text = article?.content
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Setting up the gradiant color on top of the image right before the ViewController appears.
        setGradientLayer()
    }
    
    // Function to set the gradiant layer of the view on top of the image.
    func setGradientLayer() {
        let colorTop =  UIColor.clear.cgColor
        let colorBottom = UIColor.black.cgColor
                    
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.gradiantView.bounds
                
        self.gradiantView.layer.insertSublayer(gradientLayer, at:0)
    }
    
    // Setting the image to either the placeholder or the article's image.
    func setImage(imageURL: String?) {
        guard let imageURL = imageURL else {
            return
        }
        imageView.downloadImage(from: imageURL)
    }
    
    // Function to convert the string "2021-10-11T19:15:23Z" to Date and then converting it into "19:15, 11 Oct 2021"
    func convertDate(dateString: String?) -> String {
        guard let dateString = dateString else {
            return "N/A"
        }

        let formatter4 = DateFormatter()
        formatter4.dateFormat = "y-M-dd'T'HH:mm:ss'Z'"

        let date = formatter4.date(from: dateString)
        formatter4.dateFormat = "HH:mm E, d MMM y"
        return formatter4.string(from: date!)
    }
}

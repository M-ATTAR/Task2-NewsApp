//
//  NewsCell.swift
//  Task 2
//
//  Created by Mohamed Attar on 11/10/2021.
//

import UIKit

class NewsCell: UITableViewCell {

    @IBOutlet weak var newsTitleLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configImage()
    }

    func configImage() {
        newsImageView.layer.cornerRadius = 15
        newsImageView.clipsToBounds = true
    }
    
    func setImage(image: String?) {
        guard let image = image else {
            newsImageView.image = UIImage(named: "placeholder")
            return
        }

        newsImageView.downloadImage(from: image)
    }
    func setNewsTitle(title: String?) {
        newsTitleLabel.text = title ?? "N/A"
    }
    func setSource(source: String?) {
        sourceLabel.text = source ?? "N/A"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

//
//  News.swift
//  Task 2
//
//  Created by Mohamed Attar on 11/10/2021.
//

import Foundation
import UIKit


// MARK: - News
struct News: Codable {
    let status: String
    let articles: [Article]
    let totalResults: Int
}

// MARK: - Article
struct Article: Codable {
    var source: Source?
    var author: String?
    var title, description: String?
    var url, urlToImage: String?
    var publishedAt: String?
    var content: String?
}

// MARK: - Source
struct Source: Codable {
    let id: String?
    var name: String?
}

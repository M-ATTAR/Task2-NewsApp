//
//  ModelManager.swift
//  Task 2
//
//  Created by Mohamed Attar on 11/10/2021.
//

import UIKit
import CoreData

// API KEY: ff9f04820b064397baaec5479fadb631
// API URL: https://newsapi.org/v2/everything?q=apple&sortBy=publishedAt&apiKey=ff9f04820b064397baaec5479fadb631&page=1
// API : https://newsapi.org/v2/top-headlines?country=us&apiKey=ff9f04820b064397baaec5479fadb631

enum ErrorMessage: String, Error {
    case unableToComplete   = "Unable to complete your request. Please check your internet connection"
    case invalidResponse    = "Invalid response from the server. Please try again."
    case invalidData        = "Invalid data. Please try again later."
    case invalidDecoding    = "Something went wrong decoding the data."
}

struct ModelManager {
    static var shared = ModelManager()
    
    private init(){}
    
    let cache = NSCache<NSString, UIImage>()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let apiKey = "a801955ba4ea4e1ebeb0e6db38e4c137"
    let baseURL = "https://newsapi.org/v2/top-headlines?country=us&apiKey="
    let searchURL = "https://newsapi.org/v2/everything?sortBy=publishedAt&apiKey="
    
    // MARK: - Network Calls Functions
    func getHeadlines(page: Int, completed: @escaping (Result<News, ErrorMessage>) -> Void) {
        let url = "\(baseURL+apiKey)&page=\(page)"
        print(url)
        guard let url = URL(string: url) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let _ = error {
                completed(.failure(.unableToComplete))
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completed(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completed(.failure(.invalidData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let news = try decoder.decode(News.self, from: data)
                completed(.success(news))
            } catch {
                completed(.failure(.invalidDecoding))
            }
        }
        
        task.resume()
    }
    
    func search(for query: String, page: Int, completed: @escaping (Result<News, ErrorMessage>) -> Void) {
        let url = "\(searchURL + apiKey)&page=\(page)&q=\(query)&sortBy=popularity"
        print(url)
        guard let url = URL(string: url) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let _ = error {
                completed(.failure(.unableToComplete))
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                completed(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completed(.failure(.invalidData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let news = try decoder.decode(News.self, from: data)
                completed(.success(news))
            } catch {
                completed(.failure(.invalidData))
            }
        }
        
        task.resume()
    }
    
    // MARK: - CoreData Functions
    func cacheArticles(articles: [Article]) {
        deleteCache()
        for article in articles {
            let newArticle = CachedArticle(context: context)

            newArticle.imageURL = article.urlToImage
            newArticle.title    = article.title
            newArticle.author   = article.author
            newArticle.content  = article.content
            newArticle.date     = article.publishedAt
            newArticle.source   = article.source?.name
            newArticle.desc     = article.description
            
            
            do {
                try context.save()
            } catch {
                print("Something went wrong while saving cache")
            }
        }
    }
    func fetchArticles() -> [CachedArticle] {
        var fetchedArticles: [CachedArticle] = []
        do {
            fetchedArticles = try context.fetch(CachedArticle.fetchRequest())
        } catch {
            print("Something went wrong while fetching cache.")
        }
        return fetchedArticles
    }
    func deleteCache() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CachedArticle")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Something went wrong while deleting cache.")
        }
    }
}




//            DispatchQueue.main.async {
//                let image = UIImageView()
//
//                if let articleImage = article.urlToImage {
//                    image.downloadImage(from: articleImage)
//                } else {
//                    image.image = UIImage(named: "placeholder")
//                }
//                let img = image.image?.pngData()
//                newArticle.image    = img
//            }

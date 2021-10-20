//
//  HomePresenter.swift
//  Task 2
//
//  Created by Mohamed Attar on 14/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

class HomeViewModel {
    
    private var tempArticles = [Article]()
    var articles = PublishSubject<[Article]>()
    var news: News?
    
    // Initiate the network call and get Articles.
    func getArticles(page: Int = 1) {
        getHeadlineArticles(page: page)
    }
    func getCache() {
        getCachedArticles()
    }
    func searchForArticles(query: String, page: Int = 1) {
        searchForArticles(for: query, page: page)
    }
    
    func networkManager(isOn: Bool) {
        if isOn {
            DispatchQueue.main.async { [weak self] in
                self?.getArticles()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.getCache()
//                self?.view?.presentError(title: "No Network Connection", message: "Please connect to the internet.")
            }
        }
    }
    
    // Getting the headlines articles from the server
    private func getHeadlineArticles(page: Int = 1) {
        ModelManager.shared.getHeadlines(page: page) { [weak self] result in
            guard let self = self else {return}
            switch result {
                
            case .success(let news):
                if page == 1 {
                    self.tempArticles = news.articles
                    ModelManager.shared.cacheArticles(articles: news.articles)
                } else {
                    self.tempArticles.append(contentsOf: news.articles)
                }
                
                self.articles.onNext(self.tempArticles)
//                self.articles.onCompleted()
                self.news = news
                
            case .failure(_):
//                self.view?.presentError(title: "Something wrong happened", message: error.rawValue)
                self.getCachedArticles()
            }
        }
    }
    
    // Get Cached Articles from CoreData and convert CachedArticle object into Article object
    private func getCachedArticles() {
        let cached = ModelManager.shared.fetchArticles()
        
        var getCached = [Article]()
        
        for article in cached {
            var cachedArticle = Article()
            let source = Source(id: nil, name: article.source)
            
            cachedArticle.urlToImage    = article.imageURL
            cachedArticle.description   = article.desc
            cachedArticle.content       = article.content
            cachedArticle.author        = article.author
            cachedArticle.source        = source
            cachedArticle.title         = article.title
            cachedArticle.publishedAt   = article.date
            
            getCached.append(cachedArticle)
        }
        articles.onNext(getCached)
//        articles.onCompleted()
    }
    private func searchForArticles(for text: String, page: Int = 1) {
        ModelManager.shared.search(for: text, page: page) { [weak self] result in
            guard let self = self else {return}
            
            switch result {
            case .success(let news):
                if page == 1 {
                    self.tempArticles = news.articles
                } else {
                    self.tempArticles.append(contentsOf: news.articles)
                }
                
                self.articles.onNext(self.tempArticles)
//                self.articles.onCompleted()
                self.news = news
                
            case .failure(let error):
                print(error.rawValue)
            }
        }
    }
    
    
}

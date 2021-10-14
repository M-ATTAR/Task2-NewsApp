//
//  HomePresenter.swift
//  Task 2
//
//  Created by Mohamed Attar on 14/10/2021.
//

import Foundation


protocol HomePresenterProtocol {
    var articles: [Article] { get }
    
    func pullToRefresh()
    func getArticles(page: Int)
    func getCache()
    func networkManager(isOn: Bool)
    func searchForArticles(query: String, page: Int)
}

class HomePresenter: HomePresenterProtocol {
    
    weak var view: HomeViewController?
    init(view: HomeViewController) {
        self.view = view
    }
    
    var selectedArticle = Article()
    var articles: [Article] = []
    var news: News?
    
    func performS(article: Article, segueIdentifier: String) {
        selectedArticle = article
        view?.performSegue(withIdentifier: segueIdentifier, sender: self.view)
    }
    
    // Pull To Refresh functionality
    func pullToRefresh() {
        getHeadlineArticles()
        view?.refreshControl.endRefreshing()
    }
    
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
                self?.view?.presentError(title: "No Network Connection", message: "Please connect to the internet.")
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
                    self.articles = news.articles
                    ModelManager.shared.cacheArticles(articles: self.articles)
                } else {
                    self.articles.append(contentsOf: news.articles)
                }
                
                self.news = news
                
                DispatchQueue.main.async {
                    self.view?.tableView.reloadData()
                }
            case .failure(let error):
                self.view?.presentError(title: "Something wrong happened", message: error.rawValue)
                self.getCachedArticles()
            }
        }
    }
    
    // Get Cached Articles from CoreData and convert CachedArticle object into Article object
    private func getCachedArticles() {
        let cached = ModelManager.shared.fetchArticles()
        
        articles = []
        
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
            
            articles.append(cachedArticle)
        }
        DispatchQueue.main.async {
            self.view?.tableView.reloadData()
        }
    }
    private func searchForArticles(for text: String, page: Int = 1) {
        ModelManager.shared.search(for: text, page: page) { [weak self] result in
            guard let self = self else {return}
            
            switch result {
            case .success(let news):
                if page == 1 {
                    self.articles = news.articles
                } else {
                    self.articles.append(contentsOf: news.articles)
                }
                
                self.news = news
                DispatchQueue.main.async {
                    self.view?.tableView.reloadData()
                }
            case .failure(let e):
                self.view?.presentError(title: "Something wrong happened", message: e.rawValue)
            }
        }
    }
    
    
}

//
//  HomeViewController.swift
//  Task 2
//
//  Created by Mohamed Attar on 11/10/2021.
//

import UIKit
import Network

class HomeViewController: UIViewController {
    
    let search = UISearchController(searchResultsController: nil)
    let refreshControl = UIRefreshControl()
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    
    @IBOutlet weak var tableView: UITableView!
    
    var news: News?
    var articles = [Article]()
    var selectedArticle: Article?
    var page = 1
    var isSearching = false
    var searchQuery = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        monitorConnection()
        configureSearchController()
        getHeadlineArticles()
        configureTableView()
    }
    
    // Function to monitor the connection.
    func monitorConnection() {
        monitor.pathUpdateHandler = { [weak self] pathUpdateHandler in
            
            if pathUpdateHandler.status == .satisfied { // WiFi or Cellular is on
                DispatchQueue.main.async {
                    self?.getHeadlineArticles()
                }
            } else { // No Network Connection
                DispatchQueue.main.async { // Error: Use UIApplication Delegate only from the main thread.
                    self?.getCachedArticles()
                    self?.presentError(title: "No Network Connection", message: "Please connect to the internet.")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // Function to stop monitoring the connection.
    func stopMonitoringConnection() {
        monitor.cancel()
    }
    
    // Configuring the search controller in the navigation bar and its search bar
    func configureSearchController() {
        search.delegate = self
        search.searchBar.delegate = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search"
        navigationItem.searchController = search
    }
    
    // Configuring the table view and adding pull to refresh feature
    func configureTableView() {
        tableView.dataSource    = self
        tableView.delegate      = self
        tableView.register(UINib(nibName: "NewsCell", bundle: nil), forCellReuseIdentifier: "newsCell")
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    // The pull to refresh function
    @objc func refresh(_ sender: AnyObject) {
        getHeadlineArticles()
        refreshControl.endRefreshing()
    }
    
    // AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    func getCachedArticles() {
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
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    // Getting the headlines articles from the server
    func getHeadlineArticles(page: Int = 1) {
        ModelManager.shared.getHeadlines(page: page) { [weak self] result in
            guard let self = self else {return}
            switch result {
                
            case .success(let news):
//                self.stopMonitoringConnection()
                if page == 1 {
                    self.articles = news.articles
                    ModelManager.shared.cacheArticles(articles: self.articles)
                } else {
                    self.articles.append(contentsOf: news.articles)
                }
                
                self.news = news
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                self.presentError(title: "Something wrong happened", message: error.rawValue)
//                self.monitorConnection()
                self.getCachedArticles()
            }
        }
    }
    
    // Searching for articles with a keyword
    func searchForArticles(for text: String, page: Int = 1) {
        ModelManager.shared.search(for: text, page: page) { [weak self] result in
            guard let self = self else {return}
            
            switch result {
            case .success(let news):
//                self.stopMonitoringConnection()
                if page == 1 {
                    self.articles = news.articles
                } else {
                    self.articles.append(contentsOf: news.articles)
                }
                
                self.news = news
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let e):
                self.presentError(title: "Something wrong happened", message: e.rawValue)
//                self.monitorConnection()
            }
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsCell
        
        let article = articles[indexPath.row]
        
        cell.setNewsTitle(title: article.title)
        cell.setSource(source: article.source?.name)
        cell.setImage(image: article.urlToImage)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedArticle = articles[indexPath.row]
        
        performSegue(withIdentifier: "toArticle", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toArticle" {
            let vc = segue.destination as! ArticleViewController
            vc.article = selectedArticle
        }
    }
    
    // Pagination functionality.
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if page == 5 {
            return
        }
        guard let news = news else {return}
        
        if news.totalResults <= 20 {
            return
        }
        
        let pages = ceil( Double(news.totalResults) / Double(20))
        
        if Double(page) == pages {
            return
        }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height // Entire ScrollView
        let height = scrollView.frame.size.height // Height of the screen
        
        if offsetY > contentHeight - height {
            page += 1
            
            if isSearching {
                searchForArticles(for: searchQuery, page: page)
            } else {
                getHeadlineArticles(page: page)
            }
        }
    }
}

extension HomeViewController: UISearchControllerDelegate, UISearchBarDelegate {
    
    // Changing the placeholder to let the user know they have to press the button to initiate the search.
    // Returning to page 1.
    func willPresentSearchController(_ searchController: UISearchController) {
        search.searchBar.placeholder = "Press search button to search..."
        page = 1
    }
    
    // Returning the placeholder text and the page to 1 and setting the isSearching flag to false.
    func didDismissSearchController(_ searchController: UISearchController) {
        search.searchBar.placeholder = "Search"
        page = 1
        isSearching = false
    }
    
    // Initiating the search.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        isSearching = true
        guard let text = searchBar.text else {
            return
        }
        searchQuery = text
        searchForArticles(for: text)
    }

    // Cancelling the search and loading the headlines articles (Don't forget to load them from the CoreData Cache
    func willDismissSearchController(_ searchController: UISearchController) {
        getCachedArticles()
//        getHeadlineArticles()
    }
    
}

//
//  HomeViewController.swift
//  Task 2
//
//  Created by Mohamed Attar on 11/10/2021.
//

import UIKit
import Network

// From 260 -> 160
class HomeViewController: UIViewController {
    
    let search = UISearchController(searchResultsController: nil)
    let refreshControl = UIRefreshControl()
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    
    lazy var presenter = HomePresenter(view: self)
    
    @IBOutlet weak var tableView: UITableView!
    
    var page = 1
    var isSearching = false
    var searchQuery = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.getArticles()
        
        monitorConnection()
        configureSearchController()
        configureTableView()
    }
    
    // Function to monitor the connection.
    func monitorConnection() {
        monitor.pathUpdateHandler = { [weak self] pathUpdateHandler in
            
            if pathUpdateHandler.status == .satisfied { // WiFi or Cellular is on
                self?.presenter.networkManager(isOn: true)
            } else { // No Network Connection
                self?.presenter.networkManager(isOn: false)
            }
        }
        
        monitor.start(queue: queue)
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
        refreshControl.addAction(UIAction(handler: { _ in
            self.presenter.pullToRefresh()
        }) , for: .valueChanged)
//        refreshControl.addTarget(self, action: #selector(presenter.pullToRefresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
}

// MARK: - UITableView Data Source
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsCell
        
        let article = presenter.articles[indexPath.row]
        
        cell.setNewsTitle(title: article.title)
        cell.setSource(source: article.source?.name)
        cell.setImage(image: article.urlToImage)
        
        return cell
    }
}

// MARK: - UITableView Delegate
extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedArticle = presenter.articles[indexPath.row]
        presenter.performS(article: selectedArticle, segueIdentifier: "toArticle")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toArticle" {
            let vc = segue.destination as! ArticleViewController
            vc.article = presenter.selectedArticle
        }
    }
    
    // Pagination functionality.
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if page == 5 {
            return
        }
        guard let news = presenter.news else {return}
        
        if news.totalResults <= 20 {
            return
        }
        
        let pages = ceil( Double(news.totalResults) / Double(20))
        
        if Double(page) == pages {
            return
        }
        
        let offsetY = scrollView.contentOffset.y // Point Y
        let contentHeight = scrollView.contentSize.height // Entire ScrollView
        let height = scrollView.frame.size.height // Height of the screen
        
        if offsetY > contentHeight - height {
            page += 1
            
            if isSearching {
                presenter.searchForArticles(query: searchQuery, page: page)
            } else {
                presenter.getArticles(page: page)
            }
        }
    }
}

// MARK: - UISearchBar Delegate
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
        presenter.searchForArticles(query: text)
    }

    // Cancelling the search and loading the headlines articles (Don't forget to load them from the CoreData Cache
    func willDismissSearchController(_ searchController: UISearchController) {
        presenter.getCache()
    }
    
}

//
//  HomeViewController.swift
//  Task 2
//
//  Created by Mohamed Attar on 11/10/2021.
//

import UIKit
import Network
import RxCocoa
import RxSwift

/*
 Not working:
 1 - Pagination [Fixed]
 2 - Searching [Fixed]
 3 - Gradiant View on ArticleViewController [Fixed]
 4 - Pull To Refresh [Fixed]
 */

class HomeViewController: UIViewController {
    
    let search = UISearchController(searchResultsController: nil)
    let refreshControl = UIRefreshControl()
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")
    
    var viewModel = HomeViewModel()
    var bag = DisposeBag()
    
    @IBOutlet weak var tableView: UITableView!
    
    var page = 1
    var isSearching = false
    var searchQuery = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        monitorConnection()
        configureSearchController()
        configureTableView()
        
        bindTableData()
    }
    
    // Function to monitor the connection.
    func monitorConnection() {
        monitor.pathUpdateHandler = { [weak self] pathUpdateHandler in
            
            if pathUpdateHandler.status == .satisfied { // WiFi or Cellular is on
                self?.viewModel.networkManager(isOn: true)
            } else { // No Network Connection
                self?.viewModel.networkManager(isOn: false)
                self?.presentError(title: "No Network Connection", message: "Please connect to the internet and try again.")
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
        tableView.register(UINib(nibName: "NewsCell", bundle: nil), forCellReuseIdentifier: "newsCell")
        tableView.delegate = self
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addAction(UIAction(handler: { [weak self] _ in
            self?.viewModel.getArticles()
            self?.refreshControl.endRefreshing()
        }) , for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
}

// MARK: - Binding Data to TableView.
extension HomeViewController {
    func bindTableData() {
        // Bind articles to table.
        viewModel.articles.bind(to: tableView.rx.items(cellIdentifier: "newsCell", cellType: NewsCell.self)) { row, model, cell in
            
            cell.setNewsTitle(title: model.title)
            cell.setSource(source: model.source?.name)
            cell.setImage(image: model.urlToImage)
            
        }.disposed(by: bag)
        
        // Bind a model selected handler (When someone selects a tableView row
        tableView.rx.modelSelected(Article.self).bind { [weak self] article in
            // Push ViewController
            let articleVC = self?.storyboard?.instantiateViewController(withIdentifier: "ArticleViewController") as! ArticleViewController
            articleVC.article = article
            
            self?.navigationController?.pushViewController(articleVC, animated: true)
        }.disposed(by: bag)
        
        // Fetch items
        viewModel.getArticles()
    }
}



// MARK: - UITableView Delegate
extension HomeViewController: UITableViewDelegate {
    // Pagination functionality.
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if page == 5 {
            return
        }
        guard let news = viewModel.news else {return}

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
                viewModel.searchForArticles(query: searchQuery, page: page)
            } else {
                viewModel.getArticles(page: page)
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
        viewModel.searchForArticles(query: text)
    }

    // Cancelling the search and loading the headlines articles (Don't forget to load them from the CoreData Cache
    func willDismissSearchController(_ searchController: UISearchController) {
        viewModel.getCache()
    }
    
}

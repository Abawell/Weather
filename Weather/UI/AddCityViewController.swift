//
//  AddCityViewController.swift
//  Weather
//
//  Created by Jérôme Cabanis on 10/03/2023.
//

// To limit the number of requests to the server, the search for cities is not done continuously, but when you press the Search button.

import UIKit
import OpenWeather

protocol AddCityViewControllerDelegate: AnyObject {
	func addCityViewController(_ controller: AddCityViewController, didSelect city: CityInfo)
}

class AddCityViewController: UITableViewController {

	weak var delegate: AddCityViewControllerDelegate?

	private var cities = [CityInfo]()
	private var askForName = true

	private var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()

		searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.delegate = self
		searchController.searchBar.delegate = self
		searchController.dimsBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		if #available(iOS 13.0, *) {
			searchController.automaticallyShowsCancelButton = false
		}
		searchController.searchBar.sizeToFit()

		definesPresentationContext = true

		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false
		searchController.searchBar.becomeFirstResponder()
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		searchController.isActive = true
	}

	@IBAction func onCancel(_ sender: UIBarButtonItem) {
		presentingViewController?.dismiss(animated: true)
	}

	private func requestCities(withName name: String) {
		cities = []
		tableView.reloadData()
		OpenWeatherController.requestCities(withName: name) { [weak self] cities, error in
			guard let self else { return }
			if let cities {
				// Using a Set to get unicity of the city (same name, country and state)
				self.cities = Set(cities).sorted()
				self.askForName = false
				self.tableView.reloadData()
			} else if let error {
				let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: error.localizedDescription, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default))
				self.present(alert, animated: true)
				self.askForName = true
				self.tableView.reloadData()
			}
		}
	}

	// MARK: - Table view data source/delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cities.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! CityInfoTableViewCell
		cell.city = cities[indexPath.row]
        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let city = cities[indexPath.row]
		delegate?.addCityViewController(self, didSelect: city)
		presentingViewController?.dismiss(animated: true)
	}

	override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard askForName || cities.isEmpty else { return nil }
		let back = UIView()
		back.translatesAutoresizingMaskIntoConstraints = false
		back.backgroundColor = .clear
		back.widthAnchor.constraint(equalToConstant: tableView.frame.width).isActive = true
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		if askForName {
			label.text = NSLocalizedString("CityName", comment: "Please enter a city name")
		} else {
			label.text = NSLocalizedString("NotFound", comment: "No results found")
		}
		label.font = UIFont.preferredFont(forTextStyle: .body)
		label.textAlignment = .center
		back.addSubview(label)
		label.leftAnchor.constraint(equalTo: back.leftAnchor).isActive = true
		label.rightAnchor.constraint(equalTo: back.rightAnchor).isActive = true
		label.topAnchor.constraint(equalTo: back.topAnchor, constant: 15).isActive = true
		label.bottomAnchor.constraint(equalTo: back.bottomAnchor).isActive = true
		return back
	}
}

// MARK: - UISearchBarDelegate
extension AddCityViewController: UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		if let name = searchBar.text, !name.isEmpty {
			requestCities(withName: name)
		}
	}
}

// MARK: - UISearchControllerDelegate
extension AddCityViewController: UISearchControllerDelegate {
	func didPresentSearchController(_ searchController: UISearchController) {
		DispatchQueue.main.async { [weak self] in
			self?.searchController.searchBar.becomeFirstResponder()
		}
	 }
}

// MARK: - UISearchResultsUpdating
extension AddCityViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		// Done on searchBarSearchButtonClicked
	}
}


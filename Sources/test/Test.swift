// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import CrowdFiberKit
import Foundation
import GenericHTTPClient
import GHCAsyncHTTPClient
import GHCURLSession

@main enum Main {
	static func main() async throws {
		let client = URLSessionHTTPClient()

		let baseURL = URL(string: "")!
		let authType = CF.AuthenticationType.token("")

		let clock = ContinuousClock()
		let start = clock.now

		// var zones: [CF.Zone] = []
		// var addresses: [CF.Address] = []

		// for try await zone in CF.Zone.all(
		// 	url: baseURL,
		// 	authType: authType,
		// 	client: client
		// ) {
		// 	print("Fetched Zone \(zone.0.name) (ID: \(zone.0.id)) from page \(zone.metadata.currentPage)")
		// 	zones.append(zone.0)
		// }

		// for zone in zones {
		// 	print("Fetching addresses in Zone \(zone.name) (ID: \(zone.id))")

		var lastPage = 0
		// 	var totalAddresses = 0

		// 	for try await address in CF.Address.find(
		// 		baseURL: baseURL,
		// 		zoneID: zone.id,
		// 		hasActiveService: true,
		// 		hasOrders: true,
		// 		isVacant: true,
		// 		authType: authType,
		// 		client: client
		// 	) {
		// 		if totalAddresses == 0 {
		// 			totalAddresses = address.metadata.totalObjects
		// 			print("Total Addresses in zone \(zone.name) (ID: \(zone.id)): \(totalAddresses)")
		// 		}

		// 		if address.metadata.currentPage != lastPage {
		// 			print("Fetched addresses from page \(address.metadata.currentPage)\n")
		// 			lastPage += 1
		// 		}

		// 		addresses.append(address.0)

		// 		// print(address.0.description)
		// 		// print()
		// 	}

		// 	print()
		// }

		// let end = clock.now

		// let elaspedTime = end - start

		// print("Took \(elaspedTime.formatted(.time(pattern: .hourMinuteSecond))), fetched \(addresses.count) addresses")

		let auth = CF.Authenticator(baseURL: baseURL, authType: authType, client: client)

		// switch await CF.Order.details(id: 5050, authenticator: auth) {
		// 	case .success(let order): print(order)
		// 	case .failure(let error): print(error)
		// }

		for try await order in CF.Order.all(authenticator: auth) {
			if order.metadata.currentPage == 1 {
				print("Total Objects: \(order.metadata.totalObjects)\nTotal Pages: \(order.metadata.totalPages)")
			}

			print("Fetching details for order \(order.0.id)...")

			switch await order.0.details(authenticator: auth) {
				case let .success(order):
					print("Order Details:")
					print(order.description)
					print()
				case let .failure(error):
					print("Failed to fetch details. \(error)")
					print()
			}

			if order.metadata.currentPage != lastPage {
				print("Fetched addresses from page \(order.metadata.currentPage)\n")
				lastPage += 1
			}

			print()
		}

		let end = clock.now

		let elaspedTime = end - start

		print("Took \(elaspedTime.formatted(.time(pattern: .hourMinuteSecond)))")

		client.shutdown()
	}
}

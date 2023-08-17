// Copyright (c) 2022 Jeff Lebrun
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
		let client = AHCHTTPClient()

		let baseURL = URL(string: "")!
		let authType = CF.AuthenticationType.token("")

		let clock = ContinuousClock()
		let start = clock.now

		var zones: [CF.Zone] = []
		var addresses: [CF.Address] = []

		for try await zone in CF.Zone.all(
			url: baseURL,
			authType: authType,
			client: client
		) {
			print("Fetched Zone \(zone.0.name) (ID: \(zone.0.id)) from page \(zone.metadata.currentPage)")
			zones.append(zone.0)
		}

		for zone in zones {
			print("Fetching addresses in Zone \(zone.name) (ID: \(zone.id))")

			var lastPage = 0
			var totalAddresses = 0

			for try await address in CF.Address.find(
				baseURL: baseURL,
				zoneID: zone.id,
				hasActiveService: true,
				hasOrders: true,
				isVacant: true,
				authType: authType,
				client: client
			) {
				if totalAddresses == 0 {
					totalAddresses = address.metadata.totalObjects
					print("Total Addresses in zone \(zone.name) (ID: \(zone.id)): \(totalAddresses)")
				}

				if address.metadata.currentPage != lastPage {
					print("Fetched addresses from page \(address.metadata.currentPage)\n")
					lastPage += 1
				}

				addresses.append(address.0)

				// print(address.0.description)
				// print()
			}

			print()
		}

		let end = clock.now

		let elaspedTime = end - start

		print("Took \(elaspedTime.formatted(.time(pattern: .hourMinuteSecond))), fetched \(addresses.count) addresses")

		client.shutdown()
	}
}

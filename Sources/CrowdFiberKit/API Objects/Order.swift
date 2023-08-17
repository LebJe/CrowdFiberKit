// Copyright (c) 2022 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import ExtrasJSON
import struct Foundation.Data
import struct Foundation.URL
import GenericHTTPClient
import WebURL

public extension CF {
	struct Order {
		public let id: Int
		public let zoneID: Int?
		public let addresses: [Address]

		private let url: WebURL
		private var authType: AuthenticationType = .none
		private var client: any GHCHTTPClient

		// public static func details(
		// 	id: Int,
		// 	url: WebURL,
		// 	authType: AuthenticationType = .none,
		// 	client: any GHCHTTPClient
		// ) -> Result<Order, CF.ErrorType> {

		// }

		struct DecodableOrderType: Decodable {
			public let id: Int
			public let zoneID: Int?
			public let addresses: [Address.DecodableAddressType]

			func toMainType(baseURL: URL, authType: AuthenticationType, client: any GHCHTTPClient) -> CF.Order {
				.init(
					id: self.id,
					zoneID: self.zoneID,
					addresses: self.addresses.map({ $0.toMainType(baseURL: baseURL, authType: authType, client: client) }),
					url: WebURL(baseURL.absoluteString)!,
					authType: authType,
					client: client
				)
			}
		}
	}
}

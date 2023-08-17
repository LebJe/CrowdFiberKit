// Copyright (c) 2022 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import struct Foundation.URL
import GenericHTTPClient
import WebURL

public extension CF {
	struct AddressSequence: AsyncSequence, AsyncIteratorProtocol {
		public typealias Element = (CF.Address, metadata: PaginationMetadata)

		var paginationSeq: PaginationSequence<CF.Address.DecodableAddressType>

		let baseURL: WebURL
		let authType: AuthenticationType
		let client: any GHCHTTPClient

		init(baseURL: WebURL, allAddressesURL: WebURL, authType: AuthenticationType, client: any GHCHTTPClient) {
			self.baseURL = baseURL
			self.authType = authType
			self.client = client
			self
				.paginationSeq = PaginationSequence<CF.Address.DecodableAddressType>(
					url: allAddressesURL,
					authType: authType,
					client: client
				)
		}

		public func makeAsyncIterator() -> Self {
			self
		}

		public mutating func next() async throws -> Element? {
			if let p = try await self.paginationSeq.next() {
				return (
					p.0.toMainType(baseURL: URL(string: self.baseURL.serialized())!, authType: self.authType, client: self.client),
					p.metadata
				)
			}

			return nil
		}
	}
}

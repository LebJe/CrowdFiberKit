// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import struct Foundation.URL
import GenericHTTPClient
import WebURL

public struct PaginationMetadata {
	public let currentPage: Int
	public let totalPages: Int
	public let totalObjects: Int
}

public extension CF {
	struct PaginationSequence<E: Decodable>: AsyncSequence, AsyncIteratorProtocol {
		public typealias Element = (E, metadata: PaginationMetadata)

		public var totalObjects = 0
		private var objects: [E] = []
		private var currentIndex = 0
		private var currentPage = 1
		private var pageCount: Int? = nil
		private var nextPageExists = false
		private var url: WebURL
		private let updateURL: (Int, inout WebURL) -> Void
		private let authType: AuthenticationType
		private let client: any GHCHTTPClient

		/// - Parameters:
		///   - updateURL: Use this function to update the URL so PaginationSequence can advance to the next page.
		///   For example, if the URL has a query parameter `page_num`, then you should set `page_num` the the next page
		/// number
		/// in this closure.
		init(
			url: WebURL,
			updateURL: @escaping (Int, inout WebURL) -> Void = { nextPage, url in
				url.formParams.page = String(nextPage)
			},
			authType: AuthenticationType,
			client: any GHCHTTPClient
		) {
			self.url = url
			self.client = client
			self.authType = authType
			self.updateURL = updateURL
		}

		/// - Throws: ``CF.ErrorType``, ``GHCHTTPClient\RequestError``
		public mutating func next() async throws -> Element? {
			func fetch() async throws {
				let result = await getObjects(url: url)

				switch result {
					case let .success(objects):
						self.objects = objects
					case let .failure(error):
						throw error
				}
			}

			// First iteration, fetch objects on the first page.
			if self.objects.count == 0 && self.currentIndex == 0 && self.currentPage == 1 {
				self.updateURL(self.currentPage, &self.url)
				try await fetch()

				if self.objects.isEmpty {
					return nil
				}
			}

			// No mores objects, and no more pages
			let moreObjectsCheck = self.objects.count - 1 >= self.currentIndex
			guard moreObjectsCheck || self.nextPageExists else {
				return nil
			}

			if moreObjectsCheck {
				let value = self.objects[self.currentIndex]
				self.currentIndex += 1
				return (
					value,
					PaginationMetadata(currentPage: self.currentPage, totalPages: self.pageCount ?? 0, totalObjects: self.totalObjects)
				)
			} else {
				guard self.nextPageExists else {
					return nil
				}

				self.currentPage += 1

				self.updateURL(self.currentPage, &self.url)

				try await fetch()

				self.currentIndex = 0
				guard !self.objects.isEmpty else {
					return nil
				}

				let value = self.objects[self.currentIndex]
				self.currentIndex += 1
				return (
					value,
					PaginationMetadata(currentPage: self.currentPage, totalPages: self.pageCount ?? 0, totalObjects: self.totalObjects)
				)
			}
		}

		public func makeAsyncIterator() -> Self {
			self
		}

		private mutating func getObjects(url: WebURL) async -> Result<[E], CF.ErrorType> {
			let request = try! GHCHTTPRequest(url: url, headers: CF.defaultHeaders + self.authType.headers)

			let res = await client.send(request: request)

			switch res {
				case let .success(response):
					let pageURLs = parsePaginationLink(response.headers["Link", caseSensitive: false] ?? "")

					self.nextPageExists = pageURLs.first(where: { $0.type == .next }) != nil

					// Get total amount of pages
					if self.pageCount == nil {
						if let lastPageURL = pageURLs.first(where: { $0.type == .last }) {
							if let pageNumStr = WebURL(lastPageURL.url)!.formParams.page, let pageNum = Int(pageNumStr) {
								self.pageCount = pageNum
							}
						}
					}

					self.totalObjects = Int(response.headers["X-Total-Count", caseSensitive: false] ?? "") ?? 0

					let objectArrayOrError = handle(
						response: response,
						decodeType: [E].self
					)

					switch objectArrayOrError {
						case let .success(objectArray): return .success(objectArray)
						case let .failure(error): return .failure(error)
					}

				// var u = url
				// u.formParams.removeAll()

				case let .failure(error): return .failure(.clientError(error))
			}
		}
	}
}

// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import struct Foundation.URL
import GenericHTTPClient
import WebURL

public enum CF {
	public class Authenticator {
		var url: WebURL

		public var baseURL: URL {
			get {
				URL(string: self.url.serialized())!
			} set {
				self.url = WebURL(newValue.absoluteString)!
			}
		}

		public var authType: AuthenticationType = .none
		var client: any GHCHTTPClient

		public init(baseURL: URL, authType: AuthenticationType = .none, client: any GHCHTTPClient) {
			self.url = WebURL(baseURL.absoluteString)!
			self.authType = authType
			self.client = client
		}
	}

	static let defaultHeaders: GHCHTTPHeaders = ["Accept": "application/json"]

	public enum ErrorType: Error {
		/// Error message from CrowdFiber
		case error(String)

		/// CrowdFiber did not return any JSON
		case noResponse

		/// The object (zone, address, etc.) was not found.
		case notFound

		/// Error that occurred while encoding an object to send to CrowdFiber
		case encodingError(EncodingError)

		/// Error that occurred while decoding an object from CrowdFiber
		case decodingError(DecodingError, rawJSON: String)

		case clientError(GHCError)
		case other(Error)

		public var description: String {
			switch self {
				case let .error(str): return "Error message from CrowdFiber: \(str)"
				case .noResponse: return "CrowdFiber did not return any JSON"
				case .notFound: return "The API object you requested was not found"
				case let .decodingError(
				error,
				rawJSON
			): return "Failed to decode type: \(error.localizedDescription) (from raw: \(rawJSON))"
				case let .encodingError(error): return "Failed to encode type: \(error.localizedDescription)"
				case let .clientError(error): return "HTTP Client error: \(error.localizedDescription)"
				case let .other(error): return "Unknown error occurred: \(error.localizedDescription)"
			}
		}
	}
}

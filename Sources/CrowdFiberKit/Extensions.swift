// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import struct Foundation.URL
import GenericHTTPClient
import WebURL

extension GHCHTTPRequest {
	init(url: WebURL, method: GHCHTTPMethod = .GET, headers: GHCHTTPHeaders = [:], body: Self.HTTPBody? = nil) throws {
		try self.init(url: URL(string: url.serialized())!, method: method, headers: headers, body: body)
	}
}

extension String {
	/// Initialize `String` from an array of bytes.
	init(_ bytes: [UInt8]) {
		self = String(bytes.map({ Character(Unicode.Scalar($0)) }))
	}
}

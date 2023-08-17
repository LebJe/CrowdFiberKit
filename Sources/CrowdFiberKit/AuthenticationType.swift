// Copyright (c) 2022 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import GenericHTTPClient

public extension CF {
	enum AuthenticationType: Sendable {
		case usernameAndPassword(username: String, password: String)
		case token(String)
		case none

		var headers: GHCHTTPHeaders {
			switch self {
				case let .token(token):
					return ["Authorization": "Token \(token)"]
				case let .usernameAndPassword(username: username, password: password):
					return ["Authorization": "Bearer \("\(username):\(password)".base64)"]
				default: return [:]
			}
		}
	}
}

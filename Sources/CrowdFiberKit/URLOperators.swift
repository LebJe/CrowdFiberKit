// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import struct Foundation.URL
import WebURL

func + (lhs: URL, rhs: String) -> URL {
	lhs + [rhs]
}

func + (lhs: URL, rhs: [String]) -> URL {
	var u = lhs

	for s in rhs {
		u.appendPathComponent(s)
	}

	return u
}

/// Append a path component to `lhs`.
func + (lhs: WebURL, rhs: some StringProtocol) -> WebURL {
	var url = lhs
	url.pathComponents += [rhs]
	return url
}

/// Append path components to `lhs`.
func + <C: Collection>(lhs: WebURL, rhs: C) -> WebURL where C.Element: StringProtocol {
	var url = lhs
	url.pathComponents += rhs
	return url
}

/// Append a path component to `lhs`.
func += (lhs: inout WebURL, rhs: some StringProtocol) {
	lhs.pathComponents += [rhs]
}

/// Append path components to `lhs`.
func += <C: Collection>(lhs: inout WebURL, rhs: C) where C.Element: StringProtocol {
	lhs.pathComponents += rhs
}

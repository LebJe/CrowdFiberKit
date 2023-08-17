// Copyright (c) 2022 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import struct Foundation.Data

extension String {
	var base64: String {
		Data(self.utf8).base64EncodedString()
	}
}

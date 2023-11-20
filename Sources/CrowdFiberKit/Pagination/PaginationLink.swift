// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

func parsePaginationLink(_ link: String) -> [PaginationLink] {
	let links = link.components(separatedBy: ",")

	var dictionary: [String: String] = [:]

	links.forEach {
		let components = $0.components(separatedBy: "; ")
		guard components.count >= 2 else { return }
		let cleanPath = components[0].trimmingCharacters(in: .init(charactersIn: "<>"))
		dictionary[components[1]] = cleanPath
	}

	var ps: [PaginationLink] = []

	if let first = dictionary["rel=\"first\""] {
		ps.append(.init(url: first, type: .first))
	}

	if let last = dictionary["rel=\"last\""] {
		ps.append(.init(url: last, type: .last))
	}

	if let previous = dictionary["rel=\"prev\""] {
		ps.append(.init(url: previous, type: .previous))
	}

	if let next = dictionary["rel=\"next\""] {
		ps.append(.init(url: next, type: .next))
	}

	return ps
}

struct PaginationLink {
	let url: String
	let type: PType

	enum PType {
		case first
		case last
		case previous
		case next
	}
}

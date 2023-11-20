// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import CodableWrappers
import ExtrasJSON

import struct Foundation.Date
import struct Foundation.URL
import GenericHTTPClient
import WebURL

public extension CF {
	struct Order: Decodable {
		public let id: Int
		public let zoneID: Int?
		public let firstName: String
		public let middleName: String?
		public let lastName: String
		public let emailAddress: String?
		public let phoneNumber: String?
		public var cancelled: Bool?
		public var contracted: Bool?
		public let paidBy: String?

		@FallbackDecoding<EmptyArray>
		public var addresses: [OrderAddress]

		public var description: String {
			"""
			ID: \(self.id)
			Zone ID: \(self.zoneID != nil ? String(self.zoneID!) : "(No ID)")
			First Name: \(self.firstName)
			Full Address: \(self.middleName ?? "(No Middle Name)")
			Last Name: \(self.lastName)
			E-MAil Address: \(self.emailAddress ?? "(No E-Mail Address)")
			Phone Number: \(self.phoneNumber ?? "(No Phone Number)")
			Cancelled: \(self.cancelled ?? false)
			Contracted: \(self.contracted ?? false)
			Paid By: \(self.paidBy ?? "(None)")
			Order Addresses:
			\(self.addresses.map(\.description).joined(separator: "----------\n"))
			"""
		}

		public static func all(authenticator: Authenticator) -> PaginationSequence<Order> {
			var url = authenticator.url + "orders"
			url.formParams += ["per_page": "50"]

			return PaginationSequence<Order>(url: url, authType: authenticator.authType, client: authenticator.client)
		}

		public static func details(
			id: Int,
			authenticator: Authenticator
		) async -> Result<Order, CF.ErrorType> {
			let url = authenticator.url + "orders" + "\(id)"

			let request = try! GHCHTTPRequest(url: url, headers: CF.defaultHeaders + authenticator.authType.headers)

			let result = await sendAndHandle(request: request, client: authenticator.client, decodeType: Self.self)

			switch result {
				case let .success(order): return .success(order)
				case let .failure(error): return .failure(error)
			}
		}

		public func notes(authenticator: Authenticator) async -> PaginationSequence<Notes> {
			var url = authenticator.url + "orders" + "\(self.id)" + "notes"
			url.formParams += ["per_page": "50"]

			return PaginationSequence<Notes>(url: url, authType: authenticator.authType, client: authenticator.client)
		}

		public func createNote(
			content: String,
			noteType: String,
			authenticator: Authenticator
		) async -> Result<Void, CF.ErrorType> {
			let url = authenticator.url + "orders" + "\(self.id)" + "create_note"

			let data: [UInt8]

			do {
				data = try XJSONEncoder()
					.encode(
						CreateableNote(content: content, noteType: noteType)
					)
			} catch let error as EncodingError {
				return .failure(.encodingError(error))
			} catch {
				fatalError()
			}

			let request = try! GHCHTTPRequest(
				url: url,
				method: .POST,
				headers: CF.defaultHeaders + authenticator.authType.headers,
				body: .bytes(data)
			)

			let result = await sendAndHandle(request: request, client: authenticator.client)

			switch result {
				case .success: return .success(())
				case let .failure(error): return .failure(error)
			}
		}

		public func details(authenticator: Authenticator) async -> Result<Order, CF.ErrorType> {
			await Self.details(id: self.id, authenticator: authenticator)
		}

		public struct OrderAddress: Decodable {
			public let id: Int
			public let addressID: Int
			public let addressUnitID: Int?
			public let addressType: String
			public let addressableType: String

			@OptionalCoding<ISO8601DateCoding>
			public var createdAt: Date?

			@OptionalCoding<ISO8601DateCoding>
			public var updatedAt: Date?

			public let address: [Address]?

			public var description: String {
				"""
				ID: \(self.id)
				Address ID: \(self.addressID)
				Address Unit ID: \(self.addressUnitID != nil ? String(self.addressUnitID!) : "(No ID)")
				Addressable Type: \(self.addressableType)
				Creation Date: \(self.createdAt?.description(with: .current) ?? "(No Date)")
				Date Updated: \(self.updatedAt?.description(with: .current) ?? "(No Date)")
				Addresses: \(self.address?.map(\.description).joined(separator: "----------\n") ?? "(No Addresses)")
				"""
			}

			public struct AddressUnit: Decodable {
				public let id: Int
				public let unitPrefix: String
				public let unit: String
				public let addressID: Int

				enum CodingKeys: String, CodingKey {
					case id, unit
					case unitPrefix = "unit_prefix"
					case addressID = "address_id"
				}
			}

			enum CodingKeys: String, CodingKey {
				case id
				case addressID = "address_id"
				case addressUnitID = "address_unit_id"
				case addressType = "address_type"
				case addressableType = "addressable_type"
				case createdAt = "created_at"
				case updatedAt = "updated_at"
				case address
			}
		}

		public struct Notes: Decodable {
			public let id: Int
			public let content: String
			public let type: String

			@ISO8601DateCoding
			public var createdAt: Date

			@OptionalCoding<ISO8601DateCoding>
			public var updatedAt: Date?

			@OptionalCoding<ISO8601DateCoding>
			public var deletedAt: Date?

			public let notableID: Int

			public let notableType: String

			enum CodingKeys: String, CodingKey {
				case id, content
				case type = "note_type"
				case createdAt = "created_at"
				case updatedAt = "updated_at"
				case deletedAt = "deleted_at"
				case notableID = "notable_id"
				case notableType = "notable_type"
			}
		}

		private struct CreateableNote: Encodable {
			let content: String
			let noteType: String

			enum CodingKeys: String, CodingKey {
				case content
				case noteType = "note_type"
			}
		}

		enum CodingKeys: String, CodingKey {
			case id
			case zoneID = "zone_id"
			case firstName = "first_name"
			case middleName = "middle_name"
			case lastName = "last_name"
			case emailAddress = "email_address"
			case phoneNumber = "phone_number"
			case cancelled
			case contracted
			case paidBy = "paid_by"
			case addresses
		}
	}
}

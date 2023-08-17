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
	struct Address {
		public let id: Int
		public let addressName: String?
		public let fullAddress: String
		public let details: AddressDetails
		public let latitude: Double
		public let longitude: Double

		private let url: WebURL
		private var authType: AuthenticationType = .none
		private var client: any GHCHTTPClient

		public var description: String {
			"""
			ID: \(self.id)
			Name: \(self.addressName ?? "(No Name)")
			Full Address: \(self.fullAddress)
			Full Address (Details): \(self.details.fullAddress)
			Coordinates (x, y): \(self.longitude) \(self.latitude)")
			"""
		}

		init(
			id: Int,
			addressName: String? = nil,
			fullAddress: String,
			details: AddressDetails,
			latitude: Double,
			longitude: Double,
			url: URL,
			authType: AuthenticationType = .none,
			client: any GHCHTTPClient
		) {
			self.id = id
			self.addressName = addressName
			self.fullAddress = fullAddress
			self.details = details
			self.latitude = latitude
			self.longitude = longitude
			self.url = WebURL(url.absoluteString)! + "addresses"
			self.authType = authType
			self.client = client
		}

		public static func find(
			baseURL: URL,
			zoneID: Int? = nil,
			hasActiveService: Bool? = nil,
			hasOrders: Bool? = nil,
			isVacant: Bool? = nil,
			authType: AuthenticationType = .none,
			client: any GHCHTTPClient
		) -> AddressSequence {
			var url = WebURL(baseURL.absoluteString)! + "addresses"

			if let zoneID = zoneID {
				url.formParams.with_zones = String(zoneID)
			}

			if let hasActiveService = hasActiveService {
				url.formParams.with_service_active = hasActiveService ? "2" : "1"
			}

			if let hasOrders = hasOrders {
				url.formParams.with_orders = hasOrders ? "2" : "1"
			}

			if let isVacant = isVacant {
				url.formParams.with_vacant = isVacant ? "2" : "1"
			}

			url.formParams.per_page = "50"

			return AddressSequence(
				baseURL: WebURL(baseURL.absoluteString)!,
				allAddressesURL: url,
				authType: authType,
				client: client
			)
		}

		public struct AddressDetails {
			public let name: String?
			// let address: String

			/// Example: The "123" in "123 Main St".
			public let number: Int?

			public let preDir: String?

			/// Example: "Main"
			public let streetName: String

			/// `St`, `Ave`, ...
			public let type: String?

			public let sufDir: String?

			/// Example: "Albany"
			public let city: String

			/// Example "New York"
			public let state: String

			/// Example: "1234-5678" (Sometimes the number after the dash is omitted).
			public let zipCode: (Int, Int?)

			public var fullAddress: String {
				var s = ""

				if let num = self.number {
					s += "\(num) "
				}

				s += "\(self.streetName)"

				if let type = self.type {
					s += " \(type)"
				}

				if !s.isEmpty {
					s += ", "
				}

				s += "\(self.city), "

				s += "\(self.state) "

				s += "\(self.zipCode.0)"

				if let last = self.zipCode.1 {
					s += "-\(last)"
				}

				return s
			}

			public init(
				name: String? = nil,
				number: Int? = nil,
				preDir: String? = nil,
				streetName: String,
				type: String? = nil,
				sufDir: String? = nil,
				city: String,
				state: String,
				zipCode: (Int, Int?)
			) {
				self.name = name
				self.number = number
				self.preDir = preDir
				self.streetName = streetName
				self.type = type
				self.sufDir = sufDir
				self.city = city
				self.state = state
				self.zipCode = zipCode
			}
		}

		struct DecodableAddressType: Decodable {
			let id: Int
			let zoneID: Int?
			let addressName: String?
			let fullAddress: String
			let addressNumber: Int?
			let addressPreDir: String?
			let addressStreetName: String
			let addressType: String?
			let addressSufDir: String?
			let addressCity: String
			let addressState: String

			// first and last parts of zip code
			let addressZipCode: Int
			let addressZipCodeLast: Int?

			var timezone: String? = nil
			let latitude: Double
			let longitude: Double

			var addressDetails: AddressDetails {
				.init(
					name: self.addressName,
					number: self.addressNumber,
					preDir: self.addressPreDir,
					streetName: self.addressStreetName,
					type: self.addressType,
					sufDir: self.addressSufDir,
					city: self.addressCity,
					state: self.addressState,
					zipCode: (self.addressZipCode, self.addressZipCodeLast)
				)
			}

			func toMainType(baseURL: URL, authType: AuthenticationType, client: any GHCHTTPClient) -> CF.Address {
				CF.Address(
					id: self.id,
					addressName: self.addressName,
					fullAddress: self.fullAddress,
					details: self.addressDetails,
					latitude: self.latitude,
					longitude: self.longitude,
					url: baseURL,
					authType: authType,
					client: client
				)
			}

			enum CodingKeys: String, CodingKey {
				case id
				case zoneID = "zone_id"
				case addressName = "addr_name"
				case fullAddress = "addr_street_address"
				case addressNumber = "addr_num"
				case addressPreDir = "addr_pre_dir"
				case addressStreetName = "addr_street_name"
				case addressType = "addr_type"
				case addressSufDir = "addr_suf_dir"
				case addressCity = "addr_city"
				case addressState = "addr_state"
				case addressZipCode = "addr_zip"
				case addressZipCodeLast = "addr_zip_plus_4"
				case timezone = "addr_timezone"
				case latitude, longitude
			}

			init(from decoder: Decoder) throws {
				let container: KeyedDecodingContainer<CF.Address.DecodableAddressType.CodingKeys> = try decoder
					.container(keyedBy: CF.Address.DecodableAddressType.CodingKeys.self)

				self.id = try container.decode(Int.self, forKey: CF.Address.DecodableAddressType.CodingKeys.id)
				self.zoneID = try container.decodeIfPresent(Int.self, forKey: CF.Address.DecodableAddressType.CodingKeys.zoneID)
				self.addressName = try container.decodeIfPresent(
					String.self,
					forKey: CF.Address.DecodableAddressType.CodingKeys.addressName
				)
				self.fullAddress = try container.decode(String.self, forKey: CF.Address.DecodableAddressType.CodingKeys.fullAddress)
				let addrNum = try container.decodeIfPresent(
					String.self,
					forKey: CF.Address.DecodableAddressType.CodingKeys.addressNumber
				)
				if let addrNum = addrNum {
					self.addressNumber = Int(addrNum)
				} else {
					self.addressNumber = nil
				}

				self.addressPreDir = try container.decodeIfPresent(
					String.self,
					forKey: CF.Address.DecodableAddressType.CodingKeys.addressPreDir
				)
				self.addressStreetName = try container.decode(
					String.self,
					forKey: CF.Address.DecodableAddressType.CodingKeys.addressStreetName
				)
				self.addressType = try container.decodeIfPresent(
					String.self,
					forKey: CF.Address.DecodableAddressType.CodingKeys.addressType
				)
				self.addressSufDir = try container.decodeIfPresent(
					String.self,
					forKey: CF.Address.DecodableAddressType.CodingKeys.addressSufDir
				)
				self.addressCity = try container.decode(String.self, forKey: CF.Address.DecodableAddressType.CodingKeys.addressCity)
				self.addressState = try container.decode(
					String.self,
					forKey: CF.Address.DecodableAddressType.CodingKeys.addressState
				)
				let zipFirst = try container.decode(String.self, forKey: CF.Address.DecodableAddressType.CodingKeys.addressZipCode)
				let zipLast = try container.decodeIfPresent(
					String.self,
					forKey: CF.Address.DecodableAddressType.CodingKeys.addressZipCodeLast
				)

				guard let zipFirstNum = Int(zipFirst) else {
					throw DecodingError.typeMismatch(
						Int.self,
						.init(
							codingPath: [CodingKeys.addressZipCode],
							debugDescription: "Expected ZIP code to be an Int, found \"\(zipFirst)\" instead."
						)
					)
				}

				self.addressZipCode = zipFirstNum

				if let zipLast = zipLast {
					self.addressZipCodeLast = Int(zipLast)
				} else {
					self.addressZipCodeLast = nil
				}

				self.timezone = try container.decodeIfPresent(
					String.self,
					forKey: CF.Address.DecodableAddressType.CodingKeys.timezone
				)
				self.latitude = try container.decode(Double.self, forKey: CF.Address.DecodableAddressType.CodingKeys.latitude)
				self.longitude = try container.decode(Double.self, forKey: CF.Address.DecodableAddressType.CodingKeys.longitude)
			}
		}
	}
}

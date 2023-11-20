// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import ExtrasJSON
import struct Foundation.Data
import struct Foundation.URL
import GenericHTTPClient
@preconcurrency import JSON
import WebURL

public extension CF {
	struct Zone: Sendable, Codable {
		public let id: Int
		public var name: String
		public var type: ZoneType
		public var color: String?

		public var dynamicFields: [String: JSON]?

		public var description: String {
			"""
			ID: \(self.id)
			Name: \(self.name)
			Type: \(self.type.rawValue)
			Color: \(self.color ?? "(No color)")
			"""
		}

		/// Create a zone.
		public static func create(
			name: String,
			type: ZoneType,
			color: String? = nil,
			geometry: [[[Double]]]? = nil,
			dynamicFields: [String: JSON]? = nil,
			authenticator: Authenticator
		) async -> Result<Zone, CF.ErrorType> {
			do {
				let data = try XJSONEncoder()
					.encode(CreateUpdateZoneType(
						name: name,
						type: type,
						color: color,
						geometry: geometry,
						dynamicFields: dynamicFields
					))

				let url = authenticator.url + "zones"

				let request = try! GHCHTTPRequest(
					url: url,
					method: .POST,
					headers: (CF.defaultHeaders + ["Content-Type": "application/json"]) + authenticator.authType.headers,
					body: .bytes(data)
				)

				let result = await sendAndHandle(request: request, client: authenticator.client, decodeType: Self.self)

				switch result {
					case let .success(zone): return .success(zone)
					case let .failure(error): return .failure(error)
				}
			} catch let error as EncodingError {
				return .failure(.encodingError(error))
			} catch {
				return .failure(.other(error))
			}
		}

		/// Find a zone by ID.
		public static func find(
			id: Int,
			authenticator: Authenticator
		) async throws -> Result<Zone, CF.ErrorType> {
			let url = authenticator.url + "zones"

			let request = try! GHCHTTPRequest(url: url + String(id), headers: CF.defaultHeaders + authenticator.authType.headers)

			let result = await sendAndHandle(request: request, client: authenticator.client, decodeType: Self.self)

			switch result {
				case let .success(zone): return .success(zone)
				case let .failure(error): return .failure(error)
			}
		}

		public func geoJSON(authenticator: Authenticator) async -> Result<JSON, CF.ErrorType> {
			let request = try! GHCHTTPRequest(
				url: authenticator.url + [String(self.id), "geojson"],
				headers: CF.defaultHeaders + authenticator.authType.headers
			)

			let result = await sendAndHandle(request: request, client: authenticator.client, decodeType: JSON.self)

			switch result {
				case let .success(zone): return .success(zone)
				case let .failure(error): return .failure(error)
			}
		}

		public func update(geometry: [[[Double]]]? = nil, authenticator: Authenticator) async -> Result<Void, CF.ErrorType> {
			let cuZoneType = CreateUpdateZoneType(
				name: self.name,
				type: self.type,
				color: self.color,
				geometry: geometry,
				dynamicFields: self.dynamicFields
			)

			do {
				let request = try GHCHTTPRequest(
					url: authenticator.url + String(self.id),
					method: .PUT,
					headers: CF.defaultHeaders + ["Content-Type": "application/json"] + authenticator.authType.headers,
					body: .bytes(XJSONEncoder().encode(cuZoneType))
				)

				return await sendAndHandle(request: request, client: authenticator.client)
			} catch let error as EncodingError {
				return .failure(.encodingError(error))
			} catch {
				return .failure(.other(error))
			}
		}

		public static func all(
			authenticator: Authenticator
		) -> PaginationSequence<Zone> {
			var u = authenticator.url
			u += "zones"
			u.formParams += ["per_page": "50"]

			return PaginationSequence<Zone>(url: u, authType: authenticator.authType, client: authenticator.client)
		}

		struct CreateUpdateZoneType: Encodable {
			var name: String
			var type: ZoneType
			var color: String?
			var geometry: String?
			var dynamicFields: [String: JSON]?

			init(
				name: String,
				type: ZoneType,
				color: String? = nil,
				geometry: [[[Double]]]? = nil,
				dynamicFields: [String: JSON]? = nil
			) {
				self.name = name
				self.type = type
				self.color = color
				self.dynamicFields = dynamicFields
				if let geo = geometry {
					self.geometry = JSON.object([
						"type": .string("Polygon"),
						"coordinates": geo.json,
					]).description
				}
			}

			enum CodingKeys: String, CodingKey {
				case name
				case type = "zone_type"
				case color = "zone_color"
				case geometry = "geom"
				case dynamicFields = "dynamic_fields"
			}
		}

		public enum ZoneType: String, Sendable, Codable, Equatable {
			case inService = "in_service"
			case nonPublic = "nonpublic"
			case extended
			case reference
			case remote

			public init(fromFS: String) {
				switch fromFS.lowercased() {
					case "in-service": self = .inService
					case "private": self = .nonPublic
					case "pre-registration": self = .extended
					case "reference": self = .reference
					case "remote": self = .remote
					default: self = .remote
				}
			}
		}

		enum CodingKeys: String, CodingKey {
			case id
			case name
			case type = "zone_type"
			case color = "zone_color"
			case dynamicFields = "dynamic_fields"
		}
	}
}

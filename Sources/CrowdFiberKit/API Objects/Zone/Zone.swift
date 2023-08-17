// Copyright (c) 2022 Jeff Lebrun
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
	struct Zone: Sendable, Encodable {
		public let id: Int
		public var name: String
		public var type: ZoneType
		public var color: String?

		public var dynamicFields: [String: JSON]?

		private let url: WebURL
		private var authType: AuthenticationType = .none
		private var client: any GHCHTTPClient

		public var description: String {
			"""
			ID: \(self.id)
			Name: \(self.name)
			Type: \(self.type.rawValue)
			Color: \(self.color ?? "(No color)")
			"""
		}

		///
		/// - Parameters:
		///   - url: The base URL to te CrowdFiber API (i.e https://your-org.crowdfiber.com/api/v2/)
		init(
			id: Int,
			name: String,
			type: ZoneType,
			color: String? = nil,
			dynamicFields: [String: JSON]? = nil,
			url: URL,
			authType: AuthenticationType = .none,
			client: any GHCHTTPClient
		) {
			self.id = id
			self.name = name
			self.type = type
			self.color = color
			self.dynamicFields = dynamicFields
			self.url = WebURL(url.absoluteString)!
			self.authType = authType
			self.client = client
		}

		/// Create a zone.
		public static func create(
			name: String,
			type: ZoneType,
			color: String? = nil,
			geometry: [[[Double]]]? = nil,
			dynamicFields: [String: JSON]? = nil,
			apiRootURL: URL,
			authType: AuthenticationType = .none,
			client: any GHCHTTPClient
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

				let url = WebURL(apiRootURL.absoluteString)! + "zones"

				let request = try! GHCHTTPRequest(
					url: url,
					method: .POST,
					headers: (CF.defaultHeaders + ["Content-Type": "application/json"]) + authType.headers,
					body: .bytes(data)
				)

				let result = await sendAndHandle(request: request, client: client, decodeType: Self.DecodableZoneType.self)

				switch result {
					case let .success(zone): return .success(zone.zone(url: url, authType: authType, client: client))
					case let .failure(error): return .failure(error)
				}
			} catch let error as EncodingError {
				return .failure(.encodingError(error))
			} catch {
				return .failure(.other(error))
			}
		}

		/// Find a zone by ID.
		public static func find<C: GHCHTTPClient>(
			id: Int,
			baseURL: URL,
			authType: AuthenticationType = .none,
			client: C
		) async throws -> Result<Zone, CF.ErrorType> {
			let url = WebURL(baseURL.absoluteString)! + "zones"

			let request = try! GHCHTTPRequest(url: url + String(id), headers: CF.defaultHeaders + authType.headers)

			let result = await sendAndHandle(request: request, client: client, decodeType: Self.DecodableZoneType.self)

			switch result {
				case let .success(zone): return .success(zone.zone(url: url, authType: authType, client: client))
				case let .failure(error): return .failure(error)
			}
		}

		public var geoJSON: Result<JSON, CF.ErrorType> {
			get async throws {
				let request = try! GHCHTTPRequest(
					url: self.url + [String(self.id), "geojson"],
					headers: CF.defaultHeaders + self.authType.headers
				)

				let result = await sendAndHandle(request: request, client: client, decodeType: JSON.self)

				switch result {
					case let .success(zone): return .success(zone)
					case let .failure(error): return .failure(error)
				}
			}
		}

		public func update(geometry: [[[Double]]]? = nil) async -> Result<Void, CF.ErrorType> {
			let cuZoneType = CreateUpdateZoneType(
				name: self.name,
				type: self.type,
				color: self.color,
				geometry: geometry,
				dynamicFields: self.dynamicFields
			)

			do {
				let request = try GHCHTTPRequest(
					url: self.url + String(self.id),
					method: .PUT,
					headers: CF.defaultHeaders + ["Content-Type": "application/json"] + self.authType.headers,
					body: .bytes(XJSONEncoder().encode(cuZoneType))
				)

				return await sendAndHandle(request: request, client: self.client)
			} catch let error as EncodingError {
				return .failure(.encodingError(error))
			} catch {
				return .failure(.other(error))
			}
		}

		public static func all(
			url: URL,
			authType: AuthenticationType = .none,
			client: any GHCHTTPClient
		) -> ZoneSequence {
			var u = WebURL(url.absoluteString)!
			u += "zones"
			u.formParams += ["per_page": "50"]

			return ZoneSequence(
				baseURL: WebURL(url.absoluteString)!,
				allZonesURL: u,
				authType: authType,
				client: client
			)
		}

		enum CodingKeys: String, CodingKey {
			case id
			case name
			case type = "zone_type"
			case color = "zone_color"
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

		struct DecodableZoneType: Decodable {
			let id: Int
			let name: String
			let type: ZoneType
			var color: String? = nil
			var dynamicFields: [String: JSON]? = nil

			/// Convert to a
			/// - Parameters:
			///   - url:``Zone``
			///   - authType:
			///   - client:
			/// - Returns:
			func zone(url: WebURL, authType: AuthenticationType, client: any GHCHTTPClient) -> Zone {
				Zone(
					id: self.id,
					name: self.name,
					type: self.type,
					color: self.color,
					dynamicFields: self.dynamicFields,
					url: URL(string: url.serialized())!,
					authType: authType,
					client: client
				)
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

	enum ZoneType: String, Sendable, Codable, Equatable {
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
}

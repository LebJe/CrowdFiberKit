// Copyright (c) 2023 Jeff Lebrun
//
//  Licensed under the MIT License.
//
//  The full text of the license can be found in the file named LICENSE.

import ExtrasJSON
import GenericHTTPClient

func checkStatusCode(response: GHCHTTPResponse) -> CF.ErrorType? {
	if !(200...299).contains(response.statusCode) {
		if response.statusCode == 404 {
			return CF.ErrorType.notFound
		} else {
			return CF.ErrorType.error(String(response.body!))
		}
	}

	return nil
}

func handle<T: Decodable>(response: GHCHTTPResponse, decodeType: T.Type) -> Result<T, CF.ErrorType> {
	let error = checkStatusCode(response: response)

	guard error == nil else {
		return .failure(error!)
	}

	if response.body != nil {
		do {
			let json = try XJSONDecoder().decode(decodeType, from: response.body!)

			return .success(json)
		} catch let error as DecodingError {
			return .failure(.decodingError(
				error,
				rawJSON: String(bytes: response.body!, encoding: .utf8) ?? "Cannot convert to string)"
			))
		} catch {
			fatalError("What happened?! \(error)")
		}
	} else {
		return .failure(.noResponse)
	}
}

func sendAndHandle(
	request: GHCHTTPRequest,
	client: any GHCHTTPClient
) async -> Result<Void, CF.ErrorType> {
	let result = await client.send(request: request)

	switch result {
		case let .success(response):
			let statusCodeCheck = checkStatusCode(response: response)
			guard statusCodeCheck == nil else { return .failure(statusCodeCheck!) }
			return .success(())
		case let .failure(error): return .failure(.clientError(error))
	}
}

func sendAndHandle<T: Decodable>(
	request: GHCHTTPRequest,
	client: some GHCHTTPClient,
	decodeType: T.Type
) async -> Result<T, CF.ErrorType> {
	let result = await client.send(request: request)

	switch result {
		case let .success(response):
			let handleRes = handle(response: response, decodeType: T.self)
			switch handleRes {
				case let .success(t): return .success(t)
				case let .failure(error): return .failure(error)
			}
		case let .failure(error): return .failure(.clientError(error))
	}
}

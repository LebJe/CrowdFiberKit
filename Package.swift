// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "CrowdFiberKit",
	platforms: [.macOS(.v13), .iOS(.v15)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "CrowdFiberKit",
			targets: ["CrowdFiberKit"]
		),
		.executable(name: "test", targets: ["test"]),
	],
	dependencies: [
		// For dealing with ambiguous JSON that doesn't connect to a specific type
		.package(url: "https://github.com/skelpo/json.git", from: "1.1.4"),

		// JSON encoding and decoding without the use of Foundation in pure Swift.
		.package(url: "https://github.com/swift-extras/swift-extras-json.git", from: "0.6.0"),

		// A new URL type for Swift
		.package(url: "https://github.com/karwa/swift-url.git", from: "0.2.0"),

		.package(url: "https://github.com/LebJe/GenericHTTPClient.git", branch: "main"),
	],
	targets: [
		.executableTarget(
			name: "test",
			dependencies: [
				"CrowdFiberKit",
				.product(name: "GenericHTTPClient", package: "GenericHTTPClient"),
				.product(name: "GHCAsyncHTTPClient", package: "GenericHTTPClient"),
				.product(name: "GHCURLSession", package: "GenericHTTPClient"),
			]
		),
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "CrowdFiberKit",
			dependencies: [
				.product(name: "GenericHTTPClient", package: "GenericHTTPClient"),

				.product(name: "ExtrasJSON", package: "swift-extras-json"),
				.product(name: "JSON", package: "JSON"),
				.product(name: "WebURL", package: "swift-url"),
			]
		),
		.testTarget(
			name: "CrowdFiberKitTests",
			dependencies: [
				"CrowdFiberKit",
				.product(name: "GenericHTTPClient", package: "GenericHTTPClient"),
				.product(name: "GHCAsyncHTTPClient", package: "GenericHTTPClient"),
				.product(name: "GHCURLSession", package: "GenericHTTPClient"),
			]
		),
	]
)

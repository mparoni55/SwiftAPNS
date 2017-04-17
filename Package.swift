import PackageDescription

let package = Package(
    name: "SwiftAPNS",
	dependencies: [
		.Package(url: "https://github.com/jabwd/CapnSwift.git", versions: Version(0, 0, 1)..<Version(1,0,0))
	]
)

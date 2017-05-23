import CapnSwift
import Glibc
import Foundation

func logCallback(level: __apn_log_levels, message: String, length: UInt32) {
	print("[SwiftAPNS] Received a message: \(message)")
}

public enum SwiftAPNSError: Error {
  case swiftAPNSError(reason: String)
  
}

public struct APNSLogLevel: OptionSet {   //OptionSet
	public let rawValue: UInt32
	public init(rawValue:UInt32){self.rawValue = rawValue}

	public static let APNSLogLevelNone = APNSLogLevel(rawValue: 0b000)
	public static let APNSLogLevelInfo = APNSLogLevel(rawValue: 0b001)
	public static let APNSLogLevelError = APNSLogLevel(rawValue: 0b010)
	public static let APNSLogLevelDebug = APNSLogLevel(rawValue: 0b100)

	// https://stackoverflow.com/a/41311820/1433825
	public static func | (leftSide: APNSLogLevel, rightSide: APNSLogLevel) -> APNSLogLevel {
      return APNSLogLevel(rawValue: leftSide.rawValue | rightSide.rawValue)
   }

}

public enum ConnectionMode: Int {
	case sandbox    = 1
	case production = 0
	var libraryValue: apn_connection_mode {
		if self == .sandbox {
			return APN_MODE_SANDBOX
		}
		return APN_MODE_PRODUCTION
	}
}

public class APNS {

	let context: OpaquePointer
	let mode: ConnectionMode

	var pemAPNCertFileLocation : String?
	var pemAPNCertKeyFileLocation : String?
	
	public init(mode: ConnectionMode = .sandbox) throws{
		guard apn_library_init() == APN_SUCCESS else { 
			throw SwiftAPNSError.swiftAPNSError(reason: "[\(type(of: self))] Unable to load APN library")
		}
		guard let ctx = apn_init() else {
			throw SwiftAPNSError.swiftAPNSError(reason: "[\(type(of: self))] Unable to initialize a connection context for APN")
		}
		context = ctx
		self.mode = mode

//		configure()
//		guard try connect() == true else {
//			throw SwiftAPNSError.swiftAPNSError(reason: "SwiftAPNS Connect Failed")
//		}
	}

	deinit {
		apn_free(context)
		apn_library_free()
	}

	public func send(_ payload: APNSPayload?) throws {
		guard let payload = payload else { return }
		guard let tokens = apn_array_init(1, nil, nil) else { return }
		var rawList = [UInt8](payload.token.utf8)
		rawList.withUnsafeMutableBytes {
			(buffer) in
			let ptr = UnsafeMutableRawPointer(buffer.baseAddress!)
			apn_array_insert(tokens, ptr)
		}
		var invalidTokens: OpaquePointer? = nil
		if APN_ERROR == apn_send(context, payload.context, tokens, &invalidTokens) {
			let errorString = String(cString: apn_error_string(errno))
			print("[\(type(of: self))] An error occurred while trying to send push messages: \(errorString)")
		} else {
			print("Push message was delivered.")
			if let invalidTokensReceived = invalidTokens {

			}
		}
		apn_array_free(tokens)
	}

	private func configure() throws{
		guard let pemAPNCertFileLocation = self.pemAPNCertFileLocation else {
			throw SwiftAPNSError.swiftAPNSError(reason: "[\(type(of: self))] Must specify pemAPNCertFileLocation") 
		}
		guard let pemAPNCertKeyFileLocation = self.pemAPNCertKeyFileLocation else {
			throw SwiftAPNSError.swiftAPNSError(reason: "[\(type(of: self))] Must specify pemAPNCertKeyFileLocation")
		}

		apn_set_mode(context, mode.libraryValue) // APN_MODE_PRODUCTION
		apn_set_behavior(context, UInt32(2)) // 1 << 1, APN_OPTION_RECONNECT
		apn_set_certificate(context, pemAPNCertFileLocation, pemAPNCertKeyFileLocation, nil)
//		apn_set_certificate(context, "apn-cert.pem", "apn-key.pem", nil)
//		apn_set_log_level(context, UInt16(0));
		apn_set_log_callback(context, {
			(level, message, length) in
			let str = String(cString: message!)
			//print("Received log data [\(Unmanaged.passUnretained(self).toOpaque())]: \(str)")
			if let logHandler = APNS.logHandler {
				logHandler(APNSLogLevel(rawValue:level.rawValue), str)
			}
		});
	}

	public func setLogLevel(_ level:APNSLogLevel){
		apn_set_log_level(context, UInt16(level.rawValue));
	}

	static private var logHandler : ((APNSLogLevel, String)->())?  // this needs to be static because it gets passed to the c lib as a handler

	static public func setLogHandler(_ handler: @escaping (APNSLogLevel, String)->()){ //
		APNS.logHandler = handler

	}

	public func connect() throws -> Bool {
		try configure()
		if APN_ERROR == apn_connect(context) {
			let errorString = String(cString: apn_error_string(errno))
			throw SwiftAPNSError.swiftAPNSError(reason: "[\(type(of: self))] Unable to connect to Apple push services: \(errorString)")
		}
		return true
	}
}

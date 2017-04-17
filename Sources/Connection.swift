import CapnSwift
import Glibc
import Foundation

func logCallback(level: __apn_log_levels, message: String, length: UInt32) {
	print("Received a message: \(message)")
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

class Connection {
	let context: OpaquePointer
	let mode: ConnectionMode

	init?(mode: ConnectionMode = .sandbox) {
		guard apn_library_init() == APN_SUCCESS else {
			print("[\(type(of: self))] Unable to load APN library")
			return nil
		}
		guard let ctx = apn_init() else {
			print("[\(type(of: self))] Unable to initialize a connection context for APN")
			return nil
		}
		context = ctx
		self.mode = mode

		configure()
		guard connect() == true else {
			return nil
		}
	}

	deinit {
		apn_free(context)
		apn_library_free()
	}

	public func send(_ payload: Payload?) throws {
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

	private func configure() {
		apn_set_mode(context, mode.libraryValue) // APN_MODE_PRODUCTION
		apn_set_behavior(context, UInt32(2)) // 1 << 1, APN_OPTION_RECONNECT
		apn_set_certificate(context, "apn-cert.pem", "apn-key.pem", nil)
		apn_set_log_level(context, UInt16(4));
		apn_set_log_callback(context, {
			(level, message, length) in
			let str = String(cString: message!)
			print("Received log data: \(str)")
		});
	}

	private func connect() -> Bool {
		if APN_ERROR == apn_connect(context) {
			let errorString = String(cString: apn_error_string(errno))
			print("[\(type(of: self))] Unable to connect to Apple push services: \(errorString)")
			return false
		}
		return true
	}
}

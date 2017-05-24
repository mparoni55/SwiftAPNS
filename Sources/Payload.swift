import CapnSwift
import Foundation

extension Data {
	func hexadecimalString() -> String {
		let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
		copyBytes(to: bytes, count: count)

		var hexString = ""
		for n in 0..<count {
			let byte = bytes.advanced(by: n).pointee
			let firstSet  = (UInt(byte) >> 4) & 0xF
			let secondSet = (UInt(byte)) & 0xF
			hexString += String(format: "%X%X", firstSet, secondSet)
		}
		return hexString as String
	}
}

public class APNSPayload {
	let context: OpaquePointer
	let token: String

	convenience public init?(badge: Int, body: String, deviceToken: Data, expiration: Int = 3600) {
		
		
		self.init(badge: badge, body: body, deviceToken: deviceToken.hexadecimalString(), expiration: expiration)

	}

	public init?(badge: Int, body: String, deviceToken: String, expiration: Int = 3600){
		guard let ctx = apn_payload_init() else {
			return nil
		}
		context = ctx
		token = deviceToken

		let timestamp = Int(Date().timeIntervalSince1970) + expiration

		apn_payload_set_badge(context, Int32(badge))
		apn_payload_set_body(context, body)
		apn_payload_set_expiry(context, timestamp)
		apn_payload_set_priority(context, APN_NOTIFICATION_PRIORITY_HIGH)
	}

	deinit {
		apn_payload_free(context)
	}
}

import Glibc
import Foundation

let connection = Connection()
if connection != nil {
	print("Success! Connected to APN Services")
}

let token = "0vahCTdPHr3iPKuKrgB3Tyqzjw3EBc57jIXqEacJ22M="
let data = Data(base64Encoded: token)!

let payload = Payload(badge: 15, body: "This is a test message, you tramp!", deviceToken: data)
connection!.send(payload)



print("\(data.hexadecimalString())")
//print("\(data.hexadecimalString2())")

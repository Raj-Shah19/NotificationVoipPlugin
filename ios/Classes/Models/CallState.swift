import Foundation

struct CallState {
    let callId: String
    var status: String  // ringing, connected, onHold, ended
    var isMuted: Bool = false
    var isSpeakerOn: Bool = false
    var isCameraOn: Bool = false
    var connectedAt: Date? = nil

    func toMap() -> [String: Any?] {
        return [
            "callId": callId,
            "status": status,
            "isMuted": isMuted,
            "isSpeakerOn": isSpeakerOn,
            "isCameraOn": isCameraOn,
            "connectedAt": connectedAt.map { Int($0.timeIntervalSince1970 * 1000) }
        ]
    }
}

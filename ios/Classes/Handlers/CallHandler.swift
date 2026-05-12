import Flutter
import CallKit
import AVFoundation

public class CallHandler: NSObject, CXProviderDelegate {
    var voipEventSink: FlutterEventSink?
    var callStateSink: FlutterEventSink?

    private var callProvider: CXProvider?
    private var callController = CXCallController()
    private var activeCalls: [String: UUID] = [:]
    private var callStates: [String: CallState] = [:]
    private var callerInfo: [String: [String: Any]] = [:]
    private var appName: String = "VoIP Call"
    private var ringtone: String? = nil

    func configure(config: [String: Any]?) {
        appName = config?["appName"] as? String ?? "VoIP Call"
        ringtone = config?["ringtone"] as? String
        setupCallKit()
    }

    private func setupCallKit() {
        if callProvider != nil { return }
        let config = CXProviderConfiguration(localizedName: appName)
        config.supportsVideo = true
        config.maximumCallsPerCallGroup = 1
        config.maximumCallGroups = 1
        config.supportedHandleTypes = [.generic]
        config.includesCallsInRecents = false
        if let ringtoneName = ringtone {
            config.ringtoneSound = ringtoneName
        }
        callProvider = CXProvider(configuration: config)
        callProvider?.setDelegate(self, queue: nil)
    }

    func showIncomingCall(args: [String: Any], result: @escaping FlutterResult) {
        let callId = args["callId"] as? String ?? ""
        let callerName = args["callerName"] as? String ?? "Unknown"
        let isVideo = args["isVideo"] as? Bool ?? false
        let useNativeScreen = args["useNativeScreen"] as? Bool ?? true
        let callRingtone = args["ringtone"] as? String
        let duration = args["duration"] as? Int

        // If this call was already reported to CallKit from the VoIP push handler,
        // just update the state and return success — don't double-report.
        if activeCalls[callId] != nil {
            if var state = callStates[callId] {
                state.isCameraOn = isVideo
                callStates[callId] = state
                emitCallState(state)
            }
            result(nil)
            return
        }

        var state = CallState(callId: callId, status: "ringing")
        state.isCameraOn = isVideo
        callStates[callId] = state
        emitCallState(state)

        setupCallKit()

        // Update ringtone if per-call override is provided
        if let callRingtone = callRingtone, let provider = callProvider {
            let config = provider.configuration
            config.ringtoneSound = callRingtone
            provider.configuration = config
        }

        guard let provider = callProvider else {
            result(FlutterError(code: "CALL_ERROR", message: "CallKit provider not initialized", details: nil))
            return
        }

        let uuid = UUID()
        activeCalls[callId] = uuid
        callerInfo[callId] = ["callerName": callerName, "isVideo": isVideo]

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.hasVideo = isVideo
        update.localizedCallerName = callerName
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false

        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                self.activeCalls.removeValue(forKey: callId)
                self.callStates.removeValue(forKey: callId)
                result(FlutterError(code: "CALL_ERROR", message: error.localizedDescription, details: nil))
            } else {
                // Auto-end the call after the specified duration
                if let duration = duration, duration > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(duration)) { [weak self] in
                        guard let self = self, self.activeCalls[callId] != nil else { return }
                        // Only auto-end if still ringing (not yet answered)
                        if let state = self.callStates[callId], state.status == "ringing" {
                            self.endCall(callId: callId) { _ in }
                        }
                    }
                }
                result(nil)
            }
        }
    }

    func showOutgoingCall(args: [String: Any], result: @escaping FlutterResult) {
        setupCallKit()
        let callId = args["callId"] as? String ?? ""
        let callerName = args["callerName"] as? String ?? "Unknown"
        let isVideo = args["isVideo"] as? Bool ?? false

        // Prevent duplicate outgoing call for the same callId
        if activeCalls[callId] != nil {
            result(nil)
            return
        }

        let uuid = UUID()
        activeCalls[callId] = uuid

        var state = CallState(callId: callId, status: "ringing")
        state.isCameraOn = isVideo
        callStates[callId] = state
        emitCallState(state)

        let handle = CXHandle(type: .generic, value: callerName)
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = isVideo

        let transaction = CXTransaction(action: startCallAction)
        callController.request(transaction) { error in
            if let error = error {
                result(FlutterError(code: "CALL_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(nil)
            }
        }
    }

    func acceptCall(callId: String, result: @escaping FlutterResult) {
        guard let uuid = activeCalls[callId] else {
            result(nil); return
        }
        let answerAction = CXAnswerCallAction(call: uuid)
        let transaction = CXTransaction(action: answerAction)
        callController.request(transaction) { error in
            if let error = error {
                result(FlutterError(code: "CALL_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(nil)
            }
        }
    }

    func rejectCall(callId: String, result: @escaping FlutterResult) {
        guard let uuid = activeCalls[callId] else {
            result(nil); return
        }
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { error in
            if let error = error {
                result(FlutterError(code: "CALL_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(nil)
            }
        }
    }

    public func endCall(callId: String, result: @escaping FlutterResult) {
        guard let uuid = activeCalls[callId] else {
            result(nil); return
        }
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { error in
            if let error = error {
                result(FlutterError(code: "CALL_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(nil)
            }
        }
    }

    func endAllCalls(result: @escaping FlutterResult) {
        let callIds = Array(activeCalls.keys)
        guard !callIds.isEmpty else { result(nil); return }

        var actions: [CXEndCallAction] = []
        for (_, uuid) in activeCalls {
            actions.append(CXEndCallAction(call: uuid))
        }
        let transaction = CXTransaction()
        for action in actions {
            transaction.addAction(action)
        }
        callController.request(transaction) { error in
            if let error = error {
                result(FlutterError(code: "CALL_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(nil)
            }
        }
    }

    func setCallConnected(callId: String, result: @escaping FlutterResult) {
        guard let uuid = activeCalls[callId] else {
            result(nil); return
        }
        callProvider?.reportOutgoingCall(with: uuid, connectedAt: Date())
        if var state = callStates[callId] {
            state.status = "connected"
            state.connectedAt = Date()
            callStates[callId] = state
            emitCallState(state)
        }
        result(nil)
    }

    func getActiveCallIds(result: @escaping FlutterResult) {
        result(Array(activeCalls.keys))
    }

    func toggleMute(callId: String, result: @escaping FlutterResult) {
        guard var state = callStates[callId] else { result(nil); return }
        state.isMuted = !state.isMuted
        callStates[callId] = state

        if let uuid = activeCalls[callId] {
            let muteAction = CXSetMutedCallAction(call: uuid, muted: state.isMuted)
            let transaction = CXTransaction(action: muteAction)
            callController.request(transaction) { _ in }
        }

        emitCallState(state)
        result(nil)
    }

    func toggleSpeaker(callId: String, result: @escaping FlutterResult) {
        guard var state = callStates[callId] else { result(nil); return }
        state.isSpeakerOn = !state.isSpeakerOn
        callStates[callId] = state

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .voiceChat)
        try? session.overrideOutputAudioPort(state.isSpeakerOn ? .speaker : .none)

        emitCallState(state)
        result(nil)
    }

    func toggleCamera(callId: String, result: @escaping FlutterResult) {
        guard var state = callStates[callId] else { result(nil); return }
        state.isCameraOn = !state.isCameraOn
        callStates[callId] = state
        emitCallState(state)
        result(nil)
    }

    private func emitCallState(_ state: CallState) {
        callStateSink?(state.toMap())
    }

    /// Called directly from VoIP push handler — reports to CallKit synchronously
    /// so the PushKit completion can fire only after the call is reported.
    func reportIncomingCallFromPush(callId: String, callerName: String, isVideo: Bool, completion: @escaping () -> Void) {
        setupCallKit()

        guard let provider = callProvider else {
            // Even if provider fails, we must still call completion
            completion()
            return
        }

        let uuid = UUID()
        activeCalls[callId] = uuid
        callerInfo[callId] = ["callerName": callerName, "isVideo": isVideo]

        var state = CallState(callId: callId, status: "ringing")
        state.isCameraOn = isVideo
        callStates[callId] = state
        emitCallState(state)

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.hasVideo = isVideo
        update.localizedCallerName = callerName
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false

        provider.reportNewIncomingCall(with: uuid, update: update) { [weak self] error in
            if let error = error {
                print("[NVP] Failed to report incoming call to CallKit: \(error.localizedDescription)")
                self?.activeCalls.removeValue(forKey: callId)
                self?.callStates.removeValue(forKey: callId)
            }
            // Call PushKit completion AFTER CallKit has been notified
            completion()
        }
    }

    /// Check if there's an active call with the given ID.
    func hasActiveCall(callId: String) -> Bool {
        return activeCalls[callId] != nil
    }

    /// End an existing active call from a push notification (e.g. "cancelled" push).
    func endCallFromPush(callId: String, completion: @escaping () -> Void) {
        guard let uuid = activeCalls[callId] else {
            completion()
            return
        }
        let endAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endAction)
        callController.request(transaction) { _ in
            completion()
        }
    }

    /// Report a dummy incoming call and immediately end it.
    /// Required by iOS 13+ when a PushKit push arrives but we don't
    /// want to show the call UI (e.g. cancelled/ended/busy payloads).
    /// Uses reportCall(with:endedAt:reason:) to avoid any UI flash.
    func reportAndImmediatelyEndCall(callId: String, completion: @escaping () -> Void) {
        setupCallKit()

        guard let provider = callProvider else {
            completion()
            return
        }

        let uuid = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "")
        update.localizedCallerName = ""
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false

        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                // Immediately report the call as ended so no UI is shown.
                provider.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
            }
            completion()
        }
    }

    func dispose() {
        activeCalls.removeAll()
        callStates.removeAll()
        callerInfo.removeAll()
        answeredCalls.removeAll()
    }

    private var answeredCalls: Set<String> = []

    // MARK: - CXProviderDelegate
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        if let callId = activeCalls.first(where: { $0.value == action.callUUID })?.key {
            answeredCalls.insert(callId)
            var event: [String: Any] = ["action": "accept", "callId": callId]
            if let info = callerInfo[callId] {
                event.merge(info) { _, new in new }
            }
            if let sink = voipEventSink {
                sink(event)
            } else {
                // Buffer the event — Dart engine not ready yet (background/terminated).
                NotificationVoipPlugin.shared?.pendingCallEvents.append(event)
            }
            if var state = callStates[callId] {
                state.status = "connected"
                state.connectedAt = Date()
                callStates[callId] = state
                emitCallState(state)
            }
        }
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        if let callId = activeCalls.first(where: { $0.value == action.callUUID })?.key {
            let eventAction = answeredCalls.contains(callId) ? "ended" : "decline"
            var event: [String: Any] = ["action": eventAction, "callId": callId]
            if let info = callerInfo[callId] {
                event.merge(info) { _, new in new }
            }
            if let sink = voipEventSink {
                sink(event)
            } else {
                // Buffer the event — Dart engine not ready yet (background/terminated).
                NotificationVoipPlugin.shared?.pendingCallEvents.append(event)
            }
            if var state = callStates[callId] {
                state.status = "ended"
                callStates[callId] = state
                emitCallState(state)
            }
            answeredCalls.remove(callId)
            activeCalls.removeValue(forKey: callId)
            callStates.removeValue(forKey: callId)
            callerInfo.removeValue(forKey: callId)
        }
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
    }

    public func providerDidReset(_ provider: CXProvider) {
        activeCalls.removeAll()
        callStates.removeAll()
        callerInfo.removeAll()
        answeredCalls.removeAll()
    }

    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        // CallKit activated the audio session — configure it for voice chat
        try? audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
        try? audioSession.setActive(true)
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        try? audioSession.setActive(false)
    }
}

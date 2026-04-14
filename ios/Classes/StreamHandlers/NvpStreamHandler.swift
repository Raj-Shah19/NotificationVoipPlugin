import Flutter

class NvpStreamHandler: NSObject, FlutterStreamHandler {
    private let onSinkChanged: (FlutterEventSink?) -> Void

    init(_ onSinkChanged: @escaping (FlutterEventSink?) -> Void) {
        self.onSinkChanged = onSinkChanged
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        onSinkChanged(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        onSinkChanged(nil)
        return nil
    }
}

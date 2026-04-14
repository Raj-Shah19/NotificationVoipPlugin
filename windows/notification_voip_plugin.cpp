#include "notification_voip_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>

#include <memory>
#include <string>

namespace notification_voip_plugin {

void NotificationVoipPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "notification_voip_plugin",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NotificationVoipPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  // Register event channels with empty stream handlers
  auto inapp_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), "notification_voip_plugin/inapp_events",
      &flutter::StandardMethodCodec::GetInstance());
  auto voip_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), "notification_voip_plugin/voip_events",
      &flutter::StandardMethodCodec::GetInstance());
  auto call_state_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), "notification_voip_plugin/call_state",
      &flutter::StandardMethodCodec::GetInstance());
  auto token_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), "notification_voip_plugin/token_refresh",
      &flutter::StandardMethodCodec::GetInstance());

  auto empty_handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [](const flutter::EncodableValue* arguments,
         std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        return nullptr;
      },
      [](const flutter::EncodableValue* arguments)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        return nullptr;
      });

  auto empty_handler2 = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [](const flutter::EncodableValue* arguments,
         std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        return nullptr;
      },
      [](const flutter::EncodableValue* arguments)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        return nullptr;
      });

  auto empty_handler3 = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [](const flutter::EncodableValue* arguments,
         std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        return nullptr;
      },
      [](const flutter::EncodableValue* arguments)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        return nullptr;
      });

  auto empty_handler4 = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [](const flutter::EncodableValue* arguments,
         std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        return nullptr;
      },
      [](const flutter::EncodableValue* arguments)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        return nullptr;
      });

  inapp_channel->SetStreamHandler(std::move(empty_handler));
  voip_channel->SetStreamHandler(std::move(empty_handler2));
  call_state_channel->SetStreamHandler(std::move(empty_handler3));
  token_channel->SetStreamHandler(std::move(empty_handler4));

  registrar->AddPlugin(std::move(plugin));
}

NotificationVoipPlugin::NotificationVoipPlugin() {}
NotificationVoipPlugin::~NotificationVoipPlugin() {}

void NotificationVoipPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto &method_name = method_call.method_name();

  if (method_name == "init" || method_name == "dispose" ||
      method_name == "clearAll" || method_name == "openSettings" ||
      method_name == "setBadgeCount" || method_name == "openPhoneAccountSettings" ||
      method_name == "showIncomingCall" || method_name == "showOutgoingCall" ||
      method_name == "acceptCall" || method_name == "rejectCall" ||
      method_name == "endCall" || method_name == "toggleMute" ||
      method_name == "toggleSpeaker" || method_name == "toggleCamera") {
    result->Success(flutter::EncodableValue());
  } else if (method_name == "requestPermission" || method_name == "isPermissionGranted") {
    // Windows always grants notification permission
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "isPhoneAccountEnabled") {
    result->Success(flutter::EncodableValue(false));
  } else if (method_name == "getBadgeCount") {
    result->Success(flutter::EncodableValue(0));
  } else if (method_name == "getPushToken" || method_name == "getFCMToken" ||
             method_name == "getAPNsToken" || method_name == "getVoIPToken") {
    result->Success(flutter::EncodableValue());
  } else if (method_name == "showNotification" || method_name == "showInAppNotification") {
    // TODO: Implement WinRT Toast Notifications for full support
    // For now, return true as a stub
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

}  // namespace notification_voip_plugin

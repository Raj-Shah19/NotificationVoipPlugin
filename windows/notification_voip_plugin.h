#ifndef FLUTTER_PLUGIN_NOTIFICATION_VOIP_PLUGIN_H_
#define FLUTTER_PLUGIN_NOTIFICATION_VOIP_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <memory>

namespace notification_voip_plugin {

class NotificationVoipPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  NotificationVoipPlugin();
  virtual ~NotificationVoipPlugin();

  NotificationVoipPlugin(const NotificationVoipPlugin&) = delete;
  NotificationVoipPlugin& operator=(const NotificationVoipPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace notification_voip_plugin

#endif  // FLUTTER_PLUGIN_NOTIFICATION_VOIP_PLUGIN_H_

#include "notification_voip_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

struct _NotificationVoipPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
};

G_DEFINE_TYPE(NotificationVoipPlugin, notification_voip_plugin, g_object_get_type())

static void method_call_handler(FlMethodChannel* channel,
                                 FlMethodCall* method_call,
                                 gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (g_strcmp0(method, "init") == 0 ||
      g_strcmp0(method, "dispose") == 0 ||
      g_strcmp0(method, "clearAll") == 0 ||
      g_strcmp0(method, "openSettings") == 0 ||
      g_strcmp0(method, "setBadgeCount") == 0 ||
      g_strcmp0(method, "openPhoneAccountSettings") == 0 ||
      g_strcmp0(method, "showIncomingCall") == 0 ||
      g_strcmp0(method, "showOutgoingCall") == 0 ||
      g_strcmp0(method, "acceptCall") == 0 ||
      g_strcmp0(method, "rejectCall") == 0 ||
      g_strcmp0(method, "endCall") == 0 ||
      g_strcmp0(method, "toggleMute") == 0 ||
      g_strcmp0(method, "toggleSpeaker") == 0 ||
      g_strcmp0(method, "toggleCamera") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_null()));
  } else if (g_strcmp0(method, "requestPermission") == 0 ||
             g_strcmp0(method, "isPermissionGranted") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));
  } else if (g_strcmp0(method, "isPhoneAccountEnabled") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(FALSE)));
  } else if (g_strcmp0(method, "getBadgeCount") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_int(0)));
  } else if (g_strcmp0(method, "getPushToken") == 0 ||
             g_strcmp0(method, "getFCMToken") == 0 ||
             g_strcmp0(method, "getAPNsToken") == 0 ||
             g_strcmp0(method, "getVoIPToken") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_null()));
  } else if (g_strcmp0(method, "showNotification") == 0 ||
             g_strcmp0(method, "showInAppNotification") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void notification_voip_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(notification_voip_plugin_parent_class)->dispose(object);
}

static void notification_voip_plugin_class_init(
    NotificationVoipPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = notification_voip_plugin_dispose;
}

static void notification_voip_plugin_init(NotificationVoipPlugin* self) {}

void notification_voip_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  NotificationVoipPlugin* plugin = NOTIFICATION_VOIP_PLUGIN(
      g_object_new(notification_voip_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "notification_voip_plugin", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      plugin->channel, method_call_handler, g_object_ref(plugin),
      g_object_unref);

  g_object_unref(plugin);
}

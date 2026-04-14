package com.example.notification_voip_plugin

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

/*
 * Unit tests for the Kotlin portion of this plugin's implementation.
 *
 * Run these tests from the command line by running
 * `./gradlew testDebugUnitTest` in the `example/android/` directory,
 * or directly from IDEs that support JUnit such as Android Studio.
 */

internal class NotificationVoipPluginTest {
  @Test
  fun onMethodCall_areLiveActivitiesEnabled_returnsFalse() {
    val plugin = NotificationVoipPlugin()

    val call = MethodCall("areLiveActivitiesEnabled", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success(false)
  }

  @Test
  fun onMethodCall_unknownMethod_returnsNotImplemented() {
    val plugin = NotificationVoipPlugin()

    val call = MethodCall("nonExistentMethod", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).notImplemented()
  }

  @Test
  fun onMethodCall_endAllLiveActivities_returnsTrue() {
    val plugin = NotificationVoipPlugin()

    val call = MethodCall("endAllLiveActivities", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success(true)
  }
}

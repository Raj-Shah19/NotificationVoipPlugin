Pod::Spec.new do |s|
  s.name             = 'notification_voip_plugin'
  s.version          = '2.0.0'
  s.summary          = 'Flutter plugin for notifications and VoIP with native CallKit UI, templates, grouping, and multi-platform support.'
  s.description      = <<-DESC
A Flutter plugin for handling notifications (8 templates, grouping) and VoIP calls (CallKit, custom Flutter screen) on iOS.
                       DESC
  s.homepage         = 'https://github.com/Raj-Shah19/NotificationVoipPlugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Raj Shah' => 'rajshah@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'

  s.platform = :ios, '14.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

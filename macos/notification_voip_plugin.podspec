Pod::Spec.new do |s|
  s.name             = 'notification_voip_plugin'
  s.version          = '2.1.0'
  s.summary          = 'Flutter plugin for notifications on macOS.'
  s.description      = 'macOS notification support with templates, grouping, and badge.'
  s.homepage         = 'https://github.com/Raj-Shah19/NotificationVoipPlugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Raj Shah' => 'rajshah@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'notification_voip_plugin/Sources/notification_voip_plugin/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end

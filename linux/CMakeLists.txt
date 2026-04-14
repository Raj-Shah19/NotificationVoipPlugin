cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "notification_voip_plugin")
project(${PROJECT_NAME} LANGUAGES C)

set(PLUGIN_NAME "notification_voip_plugin_plugin")

add_library(${PLUGIN_NAME} SHARED
  "notification_voip_plugin.cc"
)

set_target_properties(${PLUGIN_NAME} PROPERTIES C_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

set(notification_voip_plugin_bundled_libraries "" PARENT_SCOPE)

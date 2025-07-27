add_executable(intro main.cpp)

target_link_libraries(
  intro
  PRIVATE portfolio_optimizer::portfolio_optimizer_options
          portfolio_optimizer::portfolio_optimizer_warnings)

target_link_system_libraries(
  intro
  PRIVATE
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog
          lefticus::tools)

target_include_directories(intro PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")

add_custom_command(
  TARGET intro POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${CMAKE_SOURCE_DIR}/data"
          "$<TARGET_FILE_DIR:intro>/data"
  COMMENT "Copying data files to build directory..."
)

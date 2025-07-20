include(GenerateExportHeader)


add_library(portfolio_lib portfolio_lib.cpp)



add_library(portfolio_optimizer::portfolio_lib ALIAS portfolio_lib)

target_link_libraries(portfolio_lib PRIVATE portfolio_optimizer_options portfolio_optimizer_warnings)

target_include_directories(portfolio_lib ${WARNING_GUARD} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                                                                  $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>)

target_compile_features(portfolio_lib PUBLIC cxx_std_20)

set_target_properties(
  portfolio_lib
  PROPERTIES VERSION ${PROJECT_VERSION}
             CXX_VISIBILITY_PRESET hidden
             VISIBILITY_INLINES_HIDDEN YES)

generate_export_header(portfolio_lib EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/include/portfolio_optimizer/portfolio_lib_export.hpp)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(portfolio_lib PUBLIC PORTFOLIO_LIB_STATIC_DEFINE)
endif()

include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(portfolio_optimizer_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(portfolio_optimizer_setup_options)
  option(portfolio_optimizer_ENABLE_HARDENING "Enable hardening" ON)
  option(portfolio_optimizer_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    portfolio_optimizer_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    portfolio_optimizer_ENABLE_HARDENING
    OFF)

  portfolio_optimizer_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR portfolio_optimizer_PACKAGING_MAINTAINER_MODE)
    option(portfolio_optimizer_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(portfolio_optimizer_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(portfolio_optimizer_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(portfolio_optimizer_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(portfolio_optimizer_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(portfolio_optimizer_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(portfolio_optimizer_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(portfolio_optimizer_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(portfolio_optimizer_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(portfolio_optimizer_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(portfolio_optimizer_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(portfolio_optimizer_ENABLE_PCH "Enable precompiled headers" OFF)
    option(portfolio_optimizer_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(portfolio_optimizer_ENABLE_IPO "Enable IPO/LTO" ON)
    option(portfolio_optimizer_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(portfolio_optimizer_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(portfolio_optimizer_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(portfolio_optimizer_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(portfolio_optimizer_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(portfolio_optimizer_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(portfolio_optimizer_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(portfolio_optimizer_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(portfolio_optimizer_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(portfolio_optimizer_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(portfolio_optimizer_ENABLE_PCH "Enable precompiled headers" OFF)
    option(portfolio_optimizer_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      portfolio_optimizer_ENABLE_IPO
      portfolio_optimizer_WARNINGS_AS_ERRORS
      portfolio_optimizer_ENABLE_USER_LINKER
      portfolio_optimizer_ENABLE_SANITIZER_ADDRESS
      portfolio_optimizer_ENABLE_SANITIZER_LEAK
      portfolio_optimizer_ENABLE_SANITIZER_UNDEFINED
      portfolio_optimizer_ENABLE_SANITIZER_THREAD
      portfolio_optimizer_ENABLE_SANITIZER_MEMORY
      portfolio_optimizer_ENABLE_UNITY_BUILD
      portfolio_optimizer_ENABLE_CLANG_TIDY
      portfolio_optimizer_ENABLE_CPPCHECK
      portfolio_optimizer_ENABLE_COVERAGE
      portfolio_optimizer_ENABLE_PCH
      portfolio_optimizer_ENABLE_CACHE)
  endif()

  portfolio_optimizer_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (portfolio_optimizer_ENABLE_SANITIZER_ADDRESS OR portfolio_optimizer_ENABLE_SANITIZER_THREAD OR portfolio_optimizer_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(portfolio_optimizer_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(portfolio_optimizer_global_options)
  if(portfolio_optimizer_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    portfolio_optimizer_enable_ipo()
  endif()

  portfolio_optimizer_supports_sanitizers()

  if(portfolio_optimizer_ENABLE_HARDENING AND portfolio_optimizer_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR portfolio_optimizer_ENABLE_SANITIZER_UNDEFINED
       OR portfolio_optimizer_ENABLE_SANITIZER_ADDRESS
       OR portfolio_optimizer_ENABLE_SANITIZER_THREAD
       OR portfolio_optimizer_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${portfolio_optimizer_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${portfolio_optimizer_ENABLE_SANITIZER_UNDEFINED}")
    portfolio_optimizer_enable_hardening(portfolio_optimizer_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(portfolio_optimizer_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(portfolio_optimizer_warnings INTERFACE)
  add_library(portfolio_optimizer_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  portfolio_optimizer_set_project_warnings(
    portfolio_optimizer_warnings
    ${portfolio_optimizer_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(portfolio_optimizer_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    portfolio_optimizer_configure_linker(portfolio_optimizer_options)
  endif()

  include(cmake/Sanitizers.cmake)
  portfolio_optimizer_enable_sanitizers(
    portfolio_optimizer_options
    ${portfolio_optimizer_ENABLE_SANITIZER_ADDRESS}
    ${portfolio_optimizer_ENABLE_SANITIZER_LEAK}
    ${portfolio_optimizer_ENABLE_SANITIZER_UNDEFINED}
    ${portfolio_optimizer_ENABLE_SANITIZER_THREAD}
    ${portfolio_optimizer_ENABLE_SANITIZER_MEMORY})

  set_target_properties(portfolio_optimizer_options PROPERTIES UNITY_BUILD ${portfolio_optimizer_ENABLE_UNITY_BUILD})

  if(portfolio_optimizer_ENABLE_PCH)
    target_precompile_headers(
      portfolio_optimizer_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(portfolio_optimizer_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    portfolio_optimizer_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(portfolio_optimizer_ENABLE_CLANG_TIDY)
    portfolio_optimizer_enable_clang_tidy(portfolio_optimizer_options ${portfolio_optimizer_WARNINGS_AS_ERRORS})
  endif()

  if(portfolio_optimizer_ENABLE_CPPCHECK)
    portfolio_optimizer_enable_cppcheck(${portfolio_optimizer_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(portfolio_optimizer_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    portfolio_optimizer_enable_coverage(portfolio_optimizer_options)
  endif()

  if(portfolio_optimizer_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(portfolio_optimizer_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(portfolio_optimizer_ENABLE_HARDENING AND NOT portfolio_optimizer_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR portfolio_optimizer_ENABLE_SANITIZER_UNDEFINED
       OR portfolio_optimizer_ENABLE_SANITIZER_ADDRESS
       OR portfolio_optimizer_ENABLE_SANITIZER_THREAD
       OR portfolio_optimizer_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    portfolio_optimizer_enable_hardening(portfolio_optimizer_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()

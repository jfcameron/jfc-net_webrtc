# © Joseph Cameron - MIT License

cmake_minimum_required(VERSION 3.21 FATAL_ERROR)

if (TARGET jfcnet_webrtc)
    return()
endif()

project(jfc-net_webrtc
    VERSION 0.1
    DESCRIPTION "the jfc-net transport interface, implemented over browser WebRTC"
    LANGUAGES CXX)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/jfc-cmake/jfclib.cmake")

option(JFCNET_WEBRTC_BUILD_TESTS "Build unit tests" ${PROJECT_IS_TOP_LEVEL})
option(JFCNET_WEBRTC_BUILD_DOCS "Build documentation" OFF)
option(JFCNET_WEBRTC_INSTALL "Generate install rules" ${PROJECT_IS_TOP_LEVEL})
option(JFCNET_WEBRTC_BUILD_PROBE "Build the standalone browser WebRTC connection probe" OFF)
option(JFCNET_WEBRTC_TEST_REAL_BROWSERS "Test WebRTC with installed Playwright browsers (requires sockets)" OFF)

if (JFCNET_WEBRTC_BUILD_DOCS)
    jfc_generate_documentation_doxygen(
        README_PATH      README.md
        OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/docs

        INCLUDE_DIRECTORIES
            include/
            docs/
    )

    if (NOT EMSCRIPTEN)
        return()
    endif()
endif()

if (NOT EMSCRIPTEN)
    message(FATAL_ERROR "jfc-net_webrtc builds for the browser only: configure with an emscripten preset")
endif()

add_subdirectory(extern)

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(CheckCXXCompilerFlag)

foreach (_strict_flag "-Werror=c++20-extensions" "-Werror=c++23-extensions")
    string(MAKE_C_IDENTIFIER "HAS${_strict_flag}" _strict_flag_symbol)

    check_cxx_compiler_flag("${_strict_flag}" ${_strict_flag_symbol})

    if (${_strict_flag_symbol})
        add_compile_options($<$<COMPILE_LANGUAGE:CXX>:${_strict_flag}>)
    endif()
endforeach()

include(GNUInstallDirs)

add_library(jfcnet_webrtc STATIC "${CMAKE_CURRENT_SOURCE_DIR}/src/webrtc_host.cpp")

add_library(jfc::net_webrtc ALIAS jfcnet_webrtc)

set_target_properties(jfcnet_webrtc PROPERTIES EXPORT_NAME net_webrtc PREFIX "lib")

target_include_directories(jfcnet_webrtc PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")

target_compile_features(jfcnet_webrtc PUBLIC cxx_std_20)

target_link_libraries(jfcnet_webrtc PUBLIC jfcnet)

set_property(TARGET jfcnet_webrtc PROPERTY INTERFACE_LINK_OPTIONS
    "$<BUILD_INTERFACE:SHELL:--js-library \"${CMAKE_CURRENT_SOURCE_DIR}/src/webrtc.js\">"
    "$<INSTALL_INTERFACE:SHELL:--js-library \"\${_IMPORT_PREFIX}/${CMAKE_INSTALL_DATADIR}/jfc-net_webrtc/webrtc.js\">")

set_property(TARGET jfcnet_webrtc PROPERTY INTERFACE_LINK_DEPENDS
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/webrtc.js>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_DATADIR}/jfc-net_webrtc/webrtc.js>")

if (JFCNET_WEBRTC_INSTALL)
    include(CMakePackageConfigHelpers)

    install(TARGETS jfcnet_webrtc
        EXPORT jfc-net_webrtc-targets
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}")

    install(FILES src/webrtc.js DESTINATION "${CMAKE_INSTALL_DATADIR}/jfc-net_webrtc")

    install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include/"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

    install(EXPORT jfc-net_webrtc-targets
        FILE jfc-net_webrtc-targets.cmake
        NAMESPACE jfc::
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/jfc-net_webrtc")

    write_basic_package_version_file(
        "${PROJECT_BINARY_DIR}/jfc-net_webrtc-config-version.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion)

    file(WRITE "${PROJECT_BINARY_DIR}/jfc-net_webrtc-config.cmake"
"include(CMakeFindDependencyMacro)
find_dependency(jfcnet 0.1)
include(\"\${CMAKE_CURRENT_LIST_DIR}/jfc-net_webrtc-targets.cmake\")
")

    install(FILES
        "${PROJECT_BINARY_DIR}/jfc-net_webrtc-config.cmake"
        "${PROJECT_BINARY_DIR}/jfc-net_webrtc-config-version.cmake"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/jfc-net_webrtc")
endif()

if (JFCNET_WEBRTC_BUILD_PROBE)
    add_executable(jfcnet_webrtc_probe test/probe.cpp)
    set_target_properties(jfcnet_webrtc_probe PROPERTIES SUFFIX ".html"
        CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON CXX_EXTENSIONS OFF)
    target_link_libraries(jfcnet_webrtc_probe PRIVATE jfcnet_webrtc)
    target_link_options(jfcnet_webrtc_probe PRIVATE -sALLOW_MEMORY_GROWTH -sEXIT_RUNTIME=1)
endif()

if (JFCNET_WEBRTC_BUILD_TESTS)
    add_subdirectory(test)
endif()

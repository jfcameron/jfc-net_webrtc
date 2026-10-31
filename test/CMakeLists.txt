# © Joseph Cameron - MIT License

find_program(JFCNET_WEBRTC_NODE NAMES node nodejs)
if (NOT JFCNET_WEBRTC_NODE)
    message(FATAL_ERROR "Node is required for the WebRTC tests")
endif()

add_test(NAME jfcnet_webrtc_contract
    COMMAND "${JFCNET_WEBRTC_NODE}" "${CMAKE_CURRENT_SOURCE_DIR}/contract.cjs")

if (JFCNET_WEBRTC_TEST_REAL_BROWSERS)
    if (TARGET jfcnet_webrtc_probe)
        set(_jfcnet_probe "$<TARGET_FILE:jfcnet_webrtc_probe>")
    else()
        set(_jfcnet_probe "")
    endif()

    add_test(NAME jfcnet_webrtc_real
        COMMAND "${JFCNET_WEBRTC_NODE}" "${CMAKE_CURRENT_SOURCE_DIR}/real.cjs" "${_jfcnet_probe}")

    set_tests_properties(jfcnet_webrtc_real PROPERTIES TIMEOUT 240)
endif()

if (JFCNET_WEBRTC_INSTALL)
    add_test(NAME jfcnet_webrtc_install
        COMMAND "${CMAKE_COMMAND}"
            "-DJFCNET_WEBRTC_BUILD_DIR=${PROJECT_BINARY_DIR}"
            "-DJFCNET_WEBRTC_FIXTURE=${CMAKE_CURRENT_SOURCE_DIR}/fixture.js"
            "-DJFCNET_WEBRTC_TOOLCHAIN=${CMAKE_TOOLCHAIN_FILE}"
            "-DJFCNET_WEBRTC_GENERATOR=${CMAKE_GENERATOR}"
            "-DJFCNET_WEBRTC_NODE=${JFCNET_WEBRTC_NODE}"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/install.cmake")
endif()

jfc_add_tests(C++_STANDARD 20
    TEST_SOURCE_FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/webrtc_conformance.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/webrtc_host_test.cpp"
    LIBRARIES
        jfcnet_webrtc
        jfcnet_conformance)

target_link_options(${JFC_TEST_TARGET} PRIVATE
    "SHELL:--pre-js \"${CMAKE_CURRENT_SOURCE_DIR}/fixture.js\"" -sALLOW_MEMORY_GROWTH -sASYNCIFY)

set_property(TARGET ${JFC_TEST_TARGET} APPEND PROPERTY LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/fixture.js")

# Asyncify unwinds main at its first sleep, so its result never becomes node's exit code
set_tests_properties(${JFC_TEST_TARGET} PROPERTIES PASS_REGULAR_EXPRESSION "All tests passed")

if (TARGET jfcnet_webrtc_probe)
    add_test(NAME jfcnet_webrtc_probe_fixture COMMAND "${JFCNET_WEBRTC_NODE}"
        "${CMAKE_CURRENT_SOURCE_DIR}/run_probe.cjs" "$<TARGET_FILE:jfcnet_webrtc_probe>")
endif()

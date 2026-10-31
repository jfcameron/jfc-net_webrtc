# © Joseph Cameron - MIT License
# Install, relocate (including a space in the path), and consume only exported API.
cmake_minimum_required(VERSION 3.21)

function(check)
    execute_process(COMMAND ${ARGV} RESULT_VARIABLE _result)
    if (NOT _result EQUAL 0)
        message(FATAL_ERROR "Install/consume command failed: ${ARGV}")
    endif()
endfunction()

set(_work "${JFCNET_WEBRTC_BUILD_DIR}/test/install-consume")
file(REMOVE_RECURSE "${_work}")
file(MAKE_DIRECTORY "${_work}/source")
check("${CMAKE_COMMAND}" --install "${JFCNET_WEBRTC_BUILD_DIR}" --prefix "${_work}/package")
file(RENAME "${_work}/package" "${_work}/relocated package")
file(WRITE "${_work}/source/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.21)
project(consumer LANGUAGES CXX)
find_package(jfc-net_webrtc CONFIG REQUIRED)
add_executable(consumer main.cpp)
set_target_properties(consumer PROPERTIES CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON CXX_EXTENSIONS OFF)
target_link_libraries(consumer PRIVATE jfc::net_webrtc)
target_link_options(consumer PRIVATE "SHELL:--pre-js \"${JFCNET_WEBRTC_FIXTURE}\"")
]=])
file(WRITE "${_work}/source/main.cpp" [=[
#include <jfc/net/webrtc_host.h>
int main() {
    jfc::net::webrtc_host connection;
    const auto id = connection.offer();
    connection.update(30000);
    const auto event = connection.poll();
    return !event || event->peer != id || event->type != jfc::net::event::kind::disconnected;
}
]=])
check("${CMAKE_COMMAND}" -S "${_work}/source" -B "${_work}/build" -G "${JFCNET_WEBRTC_GENERATOR}"
    "-DCMAKE_TOOLCHAIN_FILE=${JFCNET_WEBRTC_TOOLCHAIN}"
    "-DCMAKE_PREFIX_PATH=${_work}/relocated package"
    "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
    "-DCMAKE_CXX_FLAGS=-Wall -Wextra -Werror -fexceptions"
    "-DCMAKE_EXE_LINKER_FLAGS=-fexceptions"
    "-DJFCNET_WEBRTC_FIXTURE=${JFCNET_WEBRTC_FIXTURE}")
check("${CMAKE_COMMAND}" --build "${_work}/build" --parallel 2)
check("${JFCNET_WEBRTC_NODE}" "${_work}/build/consumer.js")

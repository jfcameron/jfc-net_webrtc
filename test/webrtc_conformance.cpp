// © Joseph Cameron - MIT License

#include "conformance.h"

#include <jfc/net/webrtc_host.h>

#include <emscripten.h>

namespace jfc::net::conformance {
    namespace {
        [[nodiscard]] std::string next_signal(webrtc_host &aHost) {
            for (;;) {
                if (auto signal = aHost.poll_signal()) return std::move(signal->description);

                wait();
            }
        }
    }

    hosts make_hosts(const std::size_t aClients) {
        const webrtc_host_settings settings;

        auto pServer = std::make_shared<webrtc_host>(settings);

        hosts out{pServer, {}, settings.most_message_bytes};

        for (std::size_t i = 0; i < aClients; ++i) {
            auto pClient = std::make_shared<webrtc_host>(settings);

            const auto peer = pServer->offer();

            (void)pClient->accept(next_signal(*pServer));

            pServer->answer(peer, next_signal(*pClient));

            out.clients.push_back(std::move(pClient));
        }

        return out;
    }

    void wait() { emscripten_sleep(0); }

    std::string_view implementation() { return "webrtc"; }
}

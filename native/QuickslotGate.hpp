#pragma once
#include <array>
#include <cstdint>

namespace ControllerTweaks {
// Each token exists only during one reflected call. Addresses are comparison
// values, never dereferenced or retained for a later frame.
struct QuickslotGate {
    struct Frame { uint64_t token{}; uintptr_t owner{}; int slot{}; bool suppress{}; };
    std::array<Frame,16> frames{};
    unsigned depth{}, overflow{};
    uint64_t serial{};
    uint64_t begin(uintptr_t owner,int slot) {
        if(depth==frames.size() || overflow) { ++overflow;return 0; }
        const auto token=++serial;
        frames[depth++]={token,owner,slot,false};return token;
    }
    bool arm(uint64_t token) {
        if(overflow || !depth || !token || frames[depth-1].token!=token) return false;
        frames[depth-1].suppress=true;return true;
    }
    bool skip(uintptr_t owner,int slot) const {
        if(overflow || !depth) return false;
        const auto& f=frames[depth-1];
        return f.suppress && f.owner==owner && f.slot==slot;
    }
    void end(uint64_t token) {
        if(!token && overflow) { --overflow;return; }
        if(!overflow && depth && frames[depth-1].token==token) --depth;
        else { depth=0;overflow=0; } // Never leave a suppression latch behind.
    }
    void clear() { depth=0;overflow=0; }
};
}

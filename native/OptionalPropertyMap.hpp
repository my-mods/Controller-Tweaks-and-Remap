#pragma once
#include <Windows.h>

namespace ControllerTweaks {
// Copy-route capability, not a prerequisite for loading the native helper.
// Map is the SDK's declared map type; its DATA symbol is never odr-used.
inline constexpr char propertyMapExport[]="?VTableLayoutMap@FProperty@Unreal@RC@@2V?$unordered_map@V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@IU?$hash@V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@@2@U?$equal_to@V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@@2@V?$allocator@U?$pair@$$CBV?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@I@std@@@2@@std@@A";
template<class Map> inline Map* optionalPropertyMap(HMODULE host=GetModuleHandleW(L"UE4SS.dll")) {
    if(!host)return nullptr;
    return reinterpret_cast<Map*>(GetProcAddress(host,propertyMapExport));
}
}

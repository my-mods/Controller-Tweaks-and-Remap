// Controller Tweaks and Remap. MIT; see LICENSE.txt.
#include <Mod/CppUserModBase.hpp>
#include <LuaMadeSimple/LuaMadeSimple.hpp>
#include <DynamicOutput/Output.hpp>
#include <Unreal/UObjectGlobals.hpp>
#include <Unreal/UnrealInitializer.hpp>
#include <Unreal/Property/FEnumProperty.hpp>
#include <Unreal/CoreUObject/UObject/Class.hpp>
#include <Unreal/CoreUObject/UObject/UnrealType.hpp>
#include <Unreal/Core/Windows/AllowWindowsPlatformTypes.hpp>
#include <Windows.h>
#include <MinHook.h>
#include <cstring>
#include "QuickslotGate.hpp"

using namespace RC;
using namespace RC::Unreal;
using Lua=LuaMadeSimple::Lua;
namespace {
using Use=uint8_t(*)(UObject*,uint8_t);
Use original{};
void* target{};
bool initialized{},warned{};
thread_local ControllerTweaks::QuickslotGate gate;
static_assert(sizeof(CppUserModBase)==192);

uint8_t intercept(UObject* owner,uint8_t slot) {
    // Success acknowledges the input without consuming anything. The Lua
    // adapter replays an accepted short release through the normal function.
    if(gate.skip(reinterpret_cast<uintptr_t>(owner),slot)) return 1;
    return original(owner,slot);
}
bool executable(const void* ptr,size_t bytes) {
    MEMORY_BASIC_INFORMATION m{};
    if(!VirtualQuery(ptr,&m,sizeof(m)) || m.State!=MEM_COMMIT || (m.Protect&(PAGE_GUARD|PAGE_NOACCESS))) return false;
    if(!(m.Protect&(PAGE_EXECUTE_READ|PAGE_EXECUTE_READWRITE|PAGE_EXECUTE_WRITECOPY))) return false;
    return reinterpret_cast<uintptr_t>(ptr)+bytes<=reinterpret_cast<uintptr_t>(m.BaseAddress)+m.RegionSize;
}
bool fail(const wchar_t* why) {
    if(!warned) { warned=true;Output::send(StringType(STR("[ControllerTweaks] Item short-press handling unavailable: "))+why+STR("\n")); }
    return false;
}
bool ready() {
    if(!IsInGameThread()) return fail(L"initialization requires the game thread");
    if(target) return true;
    auto object=UObjectGlobals::StaticFindObject<UObject*>(nullptr,nullptr,L"/Script/DogwoodInventory.InventoryQuickslotSubsystem:TriggerQuickslot");
    if(!object || !object->IsA<UFunction>()) return fail(L"InventoryQuickslotSubsystem.TriggerQuickslot is missing");
    auto fn=static_cast<UFunction*>(object);
    if(!fn->HasAnyFunctionFlags(FUNC_Native) || fn->GetNumParms()!=2 || fn->GetParmsSize()!=2 || fn->GetReturnValueOffset()!=1)
        return fail(L"TriggerQuickslot parameter layout differs");
    unsigned fields=0;
    for(auto prop:TFieldRange<FProperty>(fn)) {
        if(!prop->HasAnyPropertyFlags(CPF_Parm)) continue;
        const auto name=prop->GetName();
        if(!prop->IsA<FEnumProperty>()) return fail(L"TriggerQuickslot parameters are not byte enums");
        auto ep=static_cast<FEnumProperty*>(prop);
        if(ep->GetUnderlyingProperty()->GetElementSize()!=1) return fail(L"TriggerQuickslot enum width differs");
        if((name==L"Slot" && prop->GetOffset_Internal()==0) || (name==L"ReturnValue" && prop->GetOffset_Internal()==1)) ++fields;
        else return fail(L"TriggerQuickslot parameter identity differs");
    }
    if(fields!=2) return fail(L"TriggerQuickslot parameters are incomplete");
    auto thunk=reinterpret_cast<const uint8_t*>(fn->GetFuncPtr());
    if(!executable(thunk,0xf5)) return fail(L"TriggerQuickslot native entry is unreadable");
    // Resolve the actual implementation from the reflected native wrapper.
    // Verify its scoped call/return sequence, not a game version or file hash.
    constexpr uint8_t callPrefix[]={0x48,0x39,0x7b,0x20,0x48,0x8b,0xcd,0x8a,0x54,0x24,0x48,0x40,0x0f,0x95,0xc7,0x48,0x01,0x7b,0x20,0xe8};
    constexpr uint8_t callSuffix[]={0x48,0x8b,0x5c,0x24,0x40,0x48,0x8b,0x6c,0x24,0x50,0x88,0x06};
    // Byte encodings are generated and checked against the inspected wrapper.
    constexpr size_t at=0xc6;
    if(std::memcmp(thunk+at,callPrefix,sizeof(callPrefix)) || std::memcmp(thunk+at+sizeof(callPrefix)+4,callSuffix,sizeof(callSuffix)))
        return fail(L"TriggerQuickslot native call sequence differs or is already replaced");
    int32_t displacement{};std::memcpy(&displacement,thunk+at+sizeof(callPrefix),4);
    auto implementation=thunk+at+sizeof(callPrefix)+4+displacement;
    constexpr uint8_t prefix[]={0x48,0x89,0x5c,0x24,0x08,0x48,0x89,0x74,0x24,0x10,0x57,0x48,0x83,0xec,0x20,0x40,0x8a,0xfa,0x48,0x8b,0xd9,0xe8};
    if(!executable(implementation,0xc1) || std::memcmp(implementation,prefix,sizeof(prefix)))
        return fail(L"item-use implementation has an incompatible entry");
    // Validate the success return and epilogue used by the suppression result.
    constexpr uint8_t tail[]={0xb0,0x01,0xeb,0x02,0xb0,0x04,0x48,0x8b,0x5c,0x24,0x30,0x48,0x8b,0x74,0x24,0x38,0x48,0x83,0xc4,0x20,0x5f,0xc3};
    if(std::memcmp(implementation+0xab,tail,sizeof(tail))) return fail(L"item-use result sequence differs");
    auto status=MH_Initialize();
    if(status!=MH_OK && status!=MH_ERROR_ALREADY_INITIALIZED) return fail(L"native interception could not initialize");
    initialized=true;
    auto address=const_cast<uint8_t*>(implementation);
    if(MH_CreateHook(address,reinterpret_cast<void*>(&intercept),reinterpret_cast<void**>(&original))!=MH_OK)
        return fail(L"item-use interception could not be created");
    if(MH_EnableHook(address)!=MH_OK) { MH_RemoveHook(address);original=nullptr;return fail(L"item-use interception could not be enabled"); }
    target=address;return true;
}
}
class ControllerMod final:public CppUserModBase {
public:
    ControllerMod() { ModName=STR("Controller Tweaks and Remap");ModVersion=STR("1.7.0");ModAuthors=STR("my-mods"); }
    void on_lua_start(StringViewType name,Lua& lua,Lua&,Lua&,Lua*) override {
        if(name!=STR("DawnwalkerControllerTweaks")) return;
        gate.clear();
        lua.register_function("_CTQuickslotReady",[](const Lua& l) { l.set_bool(ready());return 1; });
        lua.register_function("_CTQuickslotBegin",[](const Lua& l) {
            auto owner=static_cast<uintptr_t>(l.get_integer(1));auto slot=static_cast<int>(l.get_integer(1));
            l.set_integer(target && IsInGameThread() ? gate.begin(owner,slot) : 0);return 1;
        });
        lua.register_function("_CTQuickslotArm",[](const Lua& l) { auto token=l.get_integer(1);l.set_bool(target && IsInGameThread() && gate.arm(token));return 1; });
        lua.register_function("_CTQuickslotEnd",[](const Lua& l) { auto token=l.get_integer(1);if(IsInGameThread())gate.end(token);return 0; });
    }
    ~ControllerMod() override {
        if(target) { MH_DisableHook(target);MH_RemoveHook(target); }
        if(initialized) MH_Uninitialize();
    }
};
extern "C" __declspec(dllexport) CppUserModBase* start_mod() { return new ControllerMod; }
extern "C" __declspec(dllexport) void uninstall_mod(CppUserModBase* mod) { delete mod; }

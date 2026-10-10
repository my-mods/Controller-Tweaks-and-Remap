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
#include <atomic>
#include <algorithm>
#include "QuickslotGate.hpp"
#include "NativeRoute.hpp"

using namespace RC;
using namespace RC::Unreal;
using Lua=LuaMadeSimple::Lua;
namespace {
using Use=uint8_t(*)(UObject*,uint8_t);
Use original{};
void* target{};
bool initialized{},warned{};
std::atomic_int logLevel{2};
thread_local ControllerTweaks::QuickslotGate gate;
static_assert(sizeof(CppUserModBase)==192);

uint8_t intercept(UObject* owner,uint8_t slot) {
    // Success acknowledges the input without consuming anything. The Lua
    // adapter replays an accepted short release through the normal function.
    if(gate.skip(reinterpret_cast<uintptr_t>(owner),slot)) return 1;
    return original(owner,slot);
}
bool fail(const wchar_t* why) {
    if(logLevel>=2&&!warned) { warned=true;Output::send(StringType(STR("[ControllerTweaks] Item short-press handling unavailable: "))+why+STR("\n")); }
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
    auto slotEnum=UObjectGlobals::StaticFindObject<UEnum*>(nullptr,nullptr,L"/Script/DogwoodSystem.EQuickslot");
    auto resultEnum=UObjectGlobals::StaticFindObject<UEnum*>(nullptr,nullptr,L"/Script/DogwoodSystem.EQuickslotResult");
    if(!slotEnum || !resultEnum) return fail(L"required quickslot enum identities are unavailable");
    // Lua's four item directions and the intercepted byte result have concrete
    // semantic values. Other enum members are not dependencies.
    const wchar_t* directions[]={L"EQuickslot::Left",L"EQuickslot::Top",L"EQuickslot::Right",L"EQuickslot::Bottom"};
    for(int i=0;i<4;++i)if(slotEnum->GetNameByValue(i).ToString()!=directions[i])return fail(L"quickslot direction values differ");
    if(resultEnum->GetNameByValue(1).ToString()!=L"EQuickslotResult::Success")return fail(L"quickslot byte 1 is not Success");
    NativeRoute::ArgumentABI abi;unsigned fields=0;
    for(auto prop:TFieldRange<FProperty>(fn)) {
        if(!prop->HasAnyPropertyFlags(CPF_Parm)) continue;
        const auto name=prop->GetName();
        if(!prop->IsA<FEnumProperty>()) return fail(L"TriggerQuickslot parameters are not byte enums");
        auto ep=static_cast<FEnumProperty*>(prop);
        auto underlying=ep->GetUnderlyingProperty();
        if(!underlying || underlying->GetElementSize()!=1 || prop->GetElementSize()!=1 || prop->GetArrayDim()!=1)
            return fail(L"TriggerQuickslot scalar enum width differs");
        const bool isReturn=prop->HasAnyPropertyFlags(CPF_ReturnParm);
        if((name==L"Slot" && prop->GetOffset_Internal()==0 && !isReturn && !prop->HasAnyPropertyFlags(CPF_OutParm|CPF_ReferenceParm) && ep->GetEnum().Get()==slotEnum)
            || (name==L"ReturnValue" && prop->GetOffset_Internal()==1 && isReturn && ep->GetEnum().Get()==resultEnum)) {
            if(!isReturn){
                const auto copy=FProperty::VTableLayoutMap.find(STR("CopyCompleteValueToScriptVM_InContainer"));
                // Optional capability: Frame-only wrappers do not call this
                // interface. Reached compiled-copy routes require its identity.
                if(copy!=FProperty::VTableLayoutMap.end()){
                    abi.copySlot=copy->second;auto copyTable=*reinterpret_cast<uintptr_t**>(prop);
                    auto copyEntry=reinterpret_cast<uint8_t*>(copyTable)+copy->second;
                    if(NativeRoute::accessible(copyEntry,sizeof(uintptr_t))){
                        const auto entry=*reinterpret_cast<uintptr_t*>(copyEntry);
                        if(NativeRoute::accessible(reinterpret_cast<void*>(entry),1,true))abi.propertyCopy=entry;
                    }
                }

            }
            const unsigned bit=isReturn?2:1;
            if(fields&bit)return fail(L"TriggerQuickslot parameter identity is duplicated");
            fields|=bit;
        }
        else return fail(L"TriggerQuickslot parameter enum identity or direction differs");
    }
    if(fields!=3) return fail(L"TriggerQuickslot parameters are incomplete");
    void* address{};
    try {
        // Prove the owner + byte argument -> direct call -> AL result route.
        // Suppression does not execute the implementation. Wrapper cleanup
        // continues normally and its encoding is not a mod requirement.
        address=reinterpret_cast<void*>(NativeRoute::validate(reinterpret_cast<uintptr_t>(fn->GetFuncPtr()),abi).implementation);
    } catch(const std::exception& error) {
        std::wstring reason;for(const char* p=error.what();*p;++p)reason+=static_cast<unsigned char>(*p);
        return fail(reason.c_str());
    }
    auto status=MH_Initialize();
    if(status!=MH_OK && status!=MH_ERROR_ALREADY_INITIALIZED) return fail(L"native interception could not initialize");
    initialized=true;
    // MinHook must decode/relocate the actual entry safely; no fixed prologue.
    if(MH_CreateHook(address,reinterpret_cast<void*>(&intercept),reinterpret_cast<void**>(&original))!=MH_OK)
        return fail(L"item-use interception could not be created");
    if(MH_EnableHook(address)!=MH_OK) { MH_RemoveHook(address);original=nullptr;return fail(L"item-use interception could not be enabled"); }
    target=address;return true;
}
}
class ControllerMod final:public CppUserModBase {
public:
    ControllerMod() { ModName=STR("Controller Tweaks and Remap");ModVersion=STR("1.8.0-dev");ModAuthors=STR("my-mods"); }
    void on_lua_start(StringViewType name,Lua& lua,Lua&,Lua&,Lua*) override {
        if(name!=STR("DawnwalkerControllerTweaks")) return;
        gate.clear();
        lua.register_function("_CTSetLogLevelV2",[](const Lua& l) {
            logLevel=static_cast<int>(std::clamp<int64_t>(l.get_integer(1),0,4));return 0;
        });
        lua.register_function("_CTQuickslotReadyLogV2",[](const Lua& l) { l.set_bool(ready());return 1; });
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

// MIT. Operation-specific Windows x64 dispatch validation; no binary identity gates.
#pragma once
#include <Windows.h>
#include <Zydis/Zydis.h>
#include <array>
#include <cstdint>
#include <cstring>
#include <limits>
#include <map>
#include <deque>
#include <stdexcept>
namespace NativeRoute {
inline bool accessible(const void* ptr,size_t size,bool code=false) {
    auto cursor=reinterpret_cast<uintptr_t>(ptr);
    if(!cursor || !size || size>(std::numeric_limits<uintptr_t>::max)()-cursor)return false;
    const auto end=cursor+size;
    while(cursor<end) {
        MEMORY_BASIC_INFORMATION m{};
        if(!VirtualQuery(reinterpret_cast<void*>(cursor),&m,sizeof(m)) || m.State!=MEM_COMMIT || (m.Protect&(PAGE_GUARD|PAGE_NOACCESS)))return false;
        const auto p=m.Protect&0xff;
        const bool execute=p==PAGE_EXECUTE_READ||p==PAGE_EXECUTE_READWRITE||p==PAGE_EXECUTE_WRITECOPY;
        if(!execute && (code || (p!=PAGE_READONLY&&p!=PAGE_READWRITE&&p!=PAGE_WRITECOPY)))return false;
        const auto base=reinterpret_cast<uintptr_t>(m.BaseAddress);
        if(m.RegionSize>(std::numeric_limits<uintptr_t>::max)()-base || base+m.RegionSize<=cursor)return false;
        cursor=base+m.RegionSize;
    }
    return true;
}
struct Instruction {ZydisDecodedInstruction ins{};std::array<ZydisDecodedOperand,ZYDIS_MAX_OPERAND_COUNT> op{};};
inline Instruction decode(uintptr_t address) {
    // Copy only individually verified bytes: a function need not occupy one region.
    std::array<uint8_t,ZYDIS_MAX_INSTRUCTION_LENGTH> bytes{};size_t n=0;
    for(;n<bytes.size() && address<=UINTPTR_MAX-n && accessible(reinterpret_cast<void*>(address+n),1,true);++n)
        std::memcpy(&bytes[n],reinterpret_cast<void*>(address+n),1);
    ZydisDecoder decoder{};ZydisDecoderInit(&decoder,ZYDIS_MACHINE_MODE_LONG_64,ZYDIS_STACK_WIDTH_64);
    Instruction d;
    if(!ZYAN_SUCCESS(ZydisDecoderDecodeFull(&decoder,bytes.data(),n,&d.ins,d.op.data())))throw std::runtime_error("native route instruction is unreadable or undecodable");
    return d;
}
inline int reg(ZydisRegister r) {
    r=ZydisRegisterGetLargestEnclosing(ZYDIS_MACHINE_MODE_LONG_64,r);
    if(r>=ZYDIS_REGISTER_RAX && r<=ZYDIS_REGISTER_R15)return int(r-ZYDIS_REGISTER_RAX);
    return -1;
}
inline bool highByte(ZydisRegister r){return r==ZYDIS_REGISTER_AH||r==ZYDIS_REGISTER_BH||r==ZYDIS_REGISTER_CH||r==ZYDIS_REGISTER_DH;}
inline bool nonvolatile(int r) {return r==reg(ZYDIS_REGISTER_RBX)||r==reg(ZYDIS_REGISTER_RBP)||r==reg(ZYDIS_REGISTER_RSI)||r==reg(ZYDIS_REGISTER_RDI)||r>=reg(ZYDIS_REGISTER_R12);}
inline uintptr_t relative(uintptr_t at,const Instruction& d,unsigned operand=0) {
    ZyanU64 address{};
    if(!ZYAN_SUCCESS(ZydisCalcAbsoluteAddress(&d.ins,&d.op[operand],at,&address)))throw std::runtime_error("native route target cannot be resolved");
    return uintptr_t(address);
}
enum class Kind {Unknown,Owner,Result,Frame,Table,StackAddress,Slot,ByteResult,FrameObject,Property,PropertyTable,PropertyCopy,Locals,Flags,Address,Constant};
struct Value {Kind kind{};int64_t detail{};bool uncertain{};bool operator==(const Value&)const=default;};
inline Value resultAlias(Value base,int64_t delta,bool uncertain=false){
    const auto hi=(std::numeric_limits<int64_t>::max)(),lo=(std::numeric_limits<int64_t>::min)();
    if((delta>0 && base.detail>hi-delta)||(delta<0 && base.detail<lo-delta))return {base.kind,0,true};
    return {base.kind,base.detail+delta,base.uncertain||uncertain};
}
struct Flow {
    std::array<Value,16> r{};std::map<int64_t,Value> memory;std::map<int64_t,unsigned> widths;int64_t stack{};uintptr_t call{},stored{};bool outTest{};int copyEqual=-1;
    bool operator==(const Flow&)const=default;
};
struct Route {uintptr_t implementation{};size_t slot{};};
// Zero means unavailable, not incompatible with a Frame-only argument route.
struct ArgumentABI {uintptr_t propertyCopy{};int64_t copySlot=0x120;};
inline bool handlerBridge(uintptr_t entry,uintptr_t target) {
    // Only forwarding ABI is a dependency: (Context, Frame, destination). Additional helper arguments are engine internals.
    // No downstream implementation or cleanup identity is inspected.
    std::array<int,16> r{};r[1]=1;r[2]=2;r[8]=3;
    for(unsigned n=0;n<16;++n){const auto d=decode(entry);auto a=d.op[0],b=d.op[1];auto m=d.ins.mnemonic;
        if(m==ZYDIS_MNEMONIC_JMP && a.type==ZYDIS_OPERAND_TYPE_IMMEDIATE && a.imm.is_relative)
            return relative(entry,d)==target && r[1]==1 && r[2]==2 && r[8]==3;
        if(m==ZYDIS_MNEMONIC_RET || m==ZYDIS_MNEMONIC_CALL || d.ins.meta.category==ZYDIS_CATEGORY_COND_BR)return false;
        int tag=0,dest=reg(a.reg.value);bool assign=false;
        if(m==ZYDIS_MNEMONIC_MOV && a.type==ZYDIS_OPERAND_TYPE_REGISTER && b.type==ZYDIS_OPERAND_TYPE_REGISTER && a.size==64 && b.size==64){int source=reg(b.reg.value);tag=source>=0?r[source]:0;assign=true;}
        if((m==ZYDIS_MNEMONIC_XOR || m==ZYDIS_MNEMONIC_SUB) && a.type==ZYDIS_OPERAND_TYPE_REGISTER && b.type==ZYDIS_OPERAND_TYPE_REGISTER && a.reg.value==b.reg.value){tag=4;assign=true;}
        if(m==ZYDIS_MNEMONIC_MOV && a.type==ZYDIS_OPERAND_TYPE_REGISTER && b.type==ZYDIS_OPERAND_TYPE_IMMEDIATE && b.imm.value.u==0){tag=4;assign=true;}
        for(unsigned i=0;i<d.ins.operand_count;++i){auto o=d.op[i];if(o.type==ZYDIS_OPERAND_TYPE_REGISTER && (o.actions&ZYDIS_OPERAND_ACTION_MASK_WRITE)){int j=reg(o.reg.value);if(j>=0)r[j]=0;}}
        if(assign && dest>=0)r[dest]=tag;entry+=d.ins.length;
    }return false;
}
inline bool frameStep(uintptr_t entry) {
    // FFrame::Step is a native opcode-dispatch boundary. Follow every value
    // route, including specialization edges; do not clone native handler bodies.
    // EX_Jump is a statement token, not a Slot value expression. Its internal
    // bytecode relocation is not a dependency of this reflected input read.
    enum {None,Frame,Context,Destination,Code,Opcode,Next,Table,Handler,Address,Scalar,Zero,Node,Relocated};
    struct State {std::array<Value,16> r{};bool advanced{},written{},simd{},control{};uintptr_t compared{},selected{};};
    State initial;initial.r[1]={Kind(Frame)};initial.r[2]={Kind(Context)};initial.r[8]={Kind(Destination)};
    std::deque<std::pair<uintptr_t,State>> work;work.push_back({entry,initial});unsigned visited=0;bool result=false;
    auto push=[&](uintptr_t at,const State& f){if(at<entry || at-entry>=1024)throw std::runtime_error("Frame argument dispatch leaves the bounded prefix");work.push_back({at,f});};
    while(!work.empty()) {
        if(++visited>512)return false;
        auto [at,f]=work.front();work.pop_front();const auto d=decode(at);const auto& a=d.op[0];const auto& b=d.op[1];auto m=d.ins.mnemonic;
        auto v=[&](const ZydisDecodedOperand& o)->Value {
            if(o.type==ZYDIS_OPERAND_TYPE_REGISTER){int i=reg(o.reg.value);auto k=i>=0?f.r[i]:Value{};return o.size==64 || int(k.kind)==Opcode || int(k.kind)==Scalar?k:Value{};}
            if(o.type==ZYDIS_OPERAND_TYPE_MEMORY){int base=reg(o.mem.base),ix=reg(o.mem.index);
                if(base>=0 && int(f.r[base].kind)==Frame && o.mem.disp.value==0x20 && o.size==64)return {Kind(Code)};
                if(base>=0 && int(f.r[base].kind)==Code && o.size==8 && o.mem.disp.value==0)return {Kind(Opcode)};
                if(base>=0 && int(f.r[base].kind)==Next && o.mem.disp.value==0)return {Kind(Scalar)};
                if(base>=0 && int(f.r[base].kind)==Frame && o.mem.disp.value!=0x20 && o.size==64)return {Kind(Node)};
                if(base>=0 && int(f.r[base].kind)==Table && ix>=0 && int(f.r[ix].kind)==Opcode && o.mem.scale==8 && o.size==64)return {Kind(Handler),f.r[base].detail};
            }return {};
        };
        const bool dispatch=f.advanced && int(f.r[1].kind)==Context && int(f.r[2].kind)==Frame && int(f.r[8].kind)==Destination;
        if(m==ZYDIS_MNEMONIC_JMP && a.type==ZYDIS_OPERAND_TYPE_REGISTER && int(v(a).kind)==Handler){if(!dispatch)return false;result=true;continue;}
        if(m==ZYDIS_MNEMONIC_JMP && a.type==ZYDIS_OPERAND_TYPE_IMMEDIATE && a.imm.is_relative && f.selected && (relative(at,d)==f.selected || handlerBridge(f.selected,relative(at,d)))){if(!dispatch)return false;result=true;continue;}
        if(m==ZYDIS_MNEMONIC_RET){if(!f.advanced || (!f.written && !(f.control && int(f.r[8].kind)==Destination)))return false;result=true;continue;}
        if(m==ZYDIS_MNEMONIC_CALL)return false;
        if(d.ins.meta.category==ZYDIS_CATEGORY_COND_BR || m==ZYDIS_MNEMONIC_JMP){
            if(a.type!=ZYDIS_OPERAND_TYPE_IMMEDIATE || !a.imm.is_relative)return false;
            auto taken=f;
            if(m==ZYDIS_MNEMONIC_JZ && f.compared){
                taken.selected=f.compared;
                // The compared handler comes from GNatives, not an address ID.
                uintptr_t table{};for(auto k:f.r)if(int(k.kind)==Handler)table=uintptr_t(k.detail);
                uintptr_t jump{};if(table && accessible(reinterpret_cast<void*>(table+6*sizeof(uintptr_t)),sizeof(uintptr_t)))std::memcpy(&jump,reinterpret_cast<void*>(table+6*sizeof(uintptr_t)),sizeof(jump));
                if(jump!=f.compared)push(relative(at,d),taken);
            }else push(relative(at,d),taken);
            if(m!=ZYDIS_MNEMONIC_JMP)push(at+d.ins.length,f);continue;
        }
        for(unsigned i=0;i<d.ins.operand_count;++i){const auto& o=d.op[i];if(o.type==ZYDIS_OPERAND_TYPE_REGISTER && o.reg.value==ZYDIS_REGISTER_RFLAGS && (o.actions&ZYDIS_OPERAND_ACTION_MASK_WRITE))f.compared=0;}
        if(m==ZYDIS_MNEMONIC_CMP)f.compared=int(v(a).kind)==Handler && int(v(b).kind)==Address?uintptr_t(v(b).detail):0;
        Value assigned{};bool assign=false;
        if((m==ZYDIS_MNEMONIC_MOV || m==ZYDIS_MNEMONIC_MOVZX || m==ZYDIS_MNEMONIC_MOVSXD) && a.type==ZYDIS_OPERAND_TYPE_REGISTER){assigned=v(b);if(a.size!=64 && int(assigned.kind)!=Opcode && int(assigned.kind)!=Scalar)assigned={};assign=true;}
        if(m==ZYDIS_MNEMONIC_LEA && a.type==ZYDIS_OPERAND_TYPE_REGISTER && a.size==64 && b.type==ZYDIS_OPERAND_TYPE_MEMORY){
            int base=reg(b.mem.base);
            if(base>=0 && (int(f.r[base].kind)==Code || int(f.r[base].kind)==Next) && b.mem.disp.value>0 && b.mem.index==ZYDIS_REGISTER_NONE){assigned={Kind(Next)};assign=true;}
            if(b.mem.base==ZYDIS_REGISTER_RIP){assigned={Kind(Address),int64_t(relative(at,d,1))};assign=true;
                // A RIP table becomes Table only at an actual indexed opcode load.
                }
        }
        if(m==ZYDIS_MNEMONIC_MOV && b.type==ZYDIS_OPERAND_TYPE_MEMORY && b.mem.index!=ZYDIS_REGISTER_NONE){int base=reg(b.mem.base),ix=reg(b.mem.index);
            if(base>=0 && ix>=0 && int(f.r[base].kind)==Address && int(f.r[ix].kind)==Opcode && b.mem.scale==8 && b.size==64){assigned={Kind(Handler),f.r[base].detail};assign=true;}}
        if((m==ZYDIS_MNEMONIC_XOR || m==ZYDIS_MNEMONIC_SUB) && a.type==ZYDIS_OPERAND_TYPE_REGISTER && b.type==ZYDIS_OPERAND_TYPE_REGISTER && a.reg.value==b.reg.value){assigned={Kind(Zero)};assign=true;}
        if(m==ZYDIS_MNEMONIC_ADD && a.type==ZYDIS_OPERAND_TYPE_REGISTER && int(v(a).kind)==Scalar && b.type==ZYDIS_OPERAND_TYPE_MEMORY && b.size==64 && b.mem.index==ZYDIS_REGISTER_NONE){int base=reg(b.mem.base);if(base>=0 && int(f.r[base].kind)==Node){assigned={Kind(Relocated)};assign=true;}}
        for(unsigned i=0;i<d.ins.operand_count;++i)if(d.op[i].type==ZYDIS_OPERAND_TYPE_REGISTER && d.op[i].reg.value==ZYDIS_REGISTER_XMM0 && (d.op[i].actions&ZYDIS_OPERAND_ACTION_MASK_WRITE))f.simd=false;
        if(m==ZYDIS_MNEMONIC_MOVSD && a.type==ZYDIS_OPERAND_TYPE_REGISTER && a.reg.value==ZYDIS_REGISTER_XMM0 && int(v(b).kind)==Scalar)f.simd=true;
        if(a.type==ZYDIS_OPERAND_TYPE_MEMORY){int base=reg(a.mem.base);
            if(m==ZYDIS_MNEMONIC_MOV && base>=0 && int(f.r[base].kind)==Frame && a.mem.disp.value==0x20 && a.size==64){if(int(v(b).kind)==Next)f.advanced=true;if(int(v(b).kind)==Relocated)f.control=true;}
            if(base>=0 && int(f.r[base].kind)==Destination && a.mem.disp.value==0 && a.mem.index==ZYDIS_REGISTER_NONE && ((m==ZYDIS_MNEMONIC_MOV && int(v(b).kind)==Scalar)||(m==ZYDIS_MNEMONIC_MOVSD && f.simd)))f.written=true;
        }
        for(unsigned i=0;i<d.ins.operand_count;++i){const auto& o=d.op[i];if(o.type==ZYDIS_OPERAND_TYPE_REGISTER && (o.actions&ZYDIS_OPERAND_ACTION_MASK_WRITE)){int j=reg(o.reg.value);if(j>=0)f.r[j]={};}}
        if(assign){int j=reg(a.reg.value);if(j>=0)f.r[j]=assigned;}
        push(at+d.ins.length,f);
    }return result;
}
inline Route validate(uintptr_t entry,const ArgumentABI& abi={}) {
    // This is a bounded abstract interpreter of the reflected wrapper's reachable
    // control flow, not a function signature. Only owner/byte argument, argument-read destination,
    // result destination and calling convention are dependencies. Cleanup and
    // unrelated helper instructions are decoded but never compared to a baseline.
    Flow initial;initial.r[reg(ZYDIS_REGISTER_RCX)]={Kind::Owner};
    initial.r[reg(ZYDIS_REGISTER_RDX)]={Kind::Frame};initial.r[reg(ZYDIS_REGISTER_R8)]={Kind::Result};
    std::map<uintptr_t,Flow> incoming;std::deque<uintptr_t> work;incoming[entry]=initial;work.push_back(entry);
    uintptr_t selected{};size_t returns=0,iterations=0;
    auto enqueue=[&](uintptr_t address,const Flow& state) {
        if(address<entry || address-entry>=4096)throw std::runtime_error("native wrapper route leaves the verified analysis window");
        auto [it,added]=incoming.emplace(address,state);
        if(added){work.push_back(address);return;}
        Flow merged=it->second;
        if(merged.stack!=state.stack)throw std::runtime_error("native wrapper stack layout is ambiguous");
        for(size_t i=0;i<merged.r.size();++i)if(merged.r[i]!=state.r[i])merged.r[i]={};
        for(auto it=merged.memory.begin();it!=merged.memory.end();) {
            auto other=state.memory.find(it->first);
            if(other==state.memory.end() || other->second!=it->second || merged.widths[it->first]!=state.widths.at(it->first)){merged.widths.erase(it->first);it=merged.memory.erase(it);}else ++it;
        }
        merged.outTest=merged.outTest&&state.outTest;
        if(merged.copyEqual!=state.copyEqual)merged.copyEqual=-1;
        if(merged.call!=state.call)merged.call=0;
        if(merged.stored!=state.stored)merged.stored=0;
        if(merged!=it->second){it->second=merged;work.push_back(address);}
    };
    while(!work.empty()) {
        if(++iterations>8192)throw std::runtime_error("native wrapper route analysis did not converge");
        const auto at=work.front();work.pop_front();auto state=incoming.at(at);const auto d=decode(at);const auto& ins=d.ins;const auto& a=d.op[0];const auto& b=d.op[1];
        const auto next=at+ins.length;
        auto value=[&](const ZydisDecodedOperand& o)->Value {
            if(o.type==ZYDIS_OPERAND_TYPE_IMMEDIATE && !o.imm.is_relative)return {Kind::Constant,o.imm.value.s};
            if(o.type==ZYDIS_OPERAND_TYPE_REGISTER){const auto i=reg(o.reg.value);auto v=i>=0?state.r[i]:Value{};
                if(highByte(o.reg.value) && (v.kind==Kind::Slot||v.kind==Kind::ByteResult))return {};
                if(o.size!=64 && v.kind!=Kind::Slot && v.kind!=Kind::ByteResult && v.kind!=Kind::Flags && v.kind!=Kind::Constant)return {};return v;}
            if(o.type==ZYDIS_OPERAND_TYPE_MEMORY && o.mem.index==ZYDIS_REGISTER_NONE) {
                const auto base=reg(o.mem.base);
                if(base>=0 && state.r[base].kind==Kind::Owner && o.mem.disp.value==0 && o.size==64)return {Kind::Table};
                if(base>=0 && state.r[base].kind==Kind::Frame && o.size==64) {
                    if(o.mem.disp.value==0x18)return {Kind::FrameObject};
                    if(o.mem.disp.value==0x88)return {Kind::Property};
                    if(o.mem.disp.value==0x28)return {Kind::Locals};
                }
                if(base>=0 && state.r[base].kind==Kind::Property) {
                    if(abi.propertyCopy && o.mem.disp.value==0 && o.size==64)return {Kind::PropertyTable};
                    if(o.mem.disp.value==0x38 && o.size==32)return {Kind::Flags};
                    if(o.mem.disp.value==0x30 && o.size==32)return {Kind::Constant,1};
                }
                if(base>=0 && state.r[base].kind==Kind::PropertyTable && o.mem.disp.value==abi.copySlot && o.size==64)return {Kind::PropertyCopy,int64_t(abi.propertyCopy)};
                int64_t key{};bool stack=false;
                if(o.mem.base==ZYDIS_REGISTER_RSP){key=state.stack+o.mem.disp.value;stack=true;}
                else if(base>=0 && state.r[base].kind==Kind::StackAddress && !state.r[base].uncertain){key=state.r[base].detail+o.mem.disp.value;stack=true;}
                if(stack){auto it=state.memory.find(key);if(it!=state.memory.end() && (o.size==state.widths.at(key)*8 || it->second.kind==Kind::Slot || it->second.kind==Kind::ByteResult))return it->second;}
            }
            return {};
        };
        // A witnessed AL delivery must remain the final byte value seen by the
        // reflected caller. Any overlapping or indexed/uncertain Result write
        // invalidates it; unrelated frame/stack/owner cleanup does not.
        for(unsigned i=0;i<ins.operand_count;++i){const auto& o=d.op[i];
            if(o.type!=ZYDIS_OPERAND_TYPE_MEMORY || !(o.actions&ZYDIS_OPERAND_ACTION_MASK_WRITE))continue;
            const int base=reg(o.mem.base);if(base<0 || state.r[base].kind!=Kind::Result)continue;
            const auto derived=resultAlias(state.r[base],o.mem.disp.value,o.mem.index!=ZYDIS_REGISTER_NONE);const auto offset=derived.detail;
            if(derived.uncertain || !o.size || (offset<=0 && offset>-int64_t((o.size+7)/8)))state.stored=0;
        }
        if(ins.mnemonic==ZYDIS_MNEMONIC_RET) {
            if(!state.stored || (selected && state.stored!=selected))throw std::runtime_error("native wrapper cannot prove owner, Frame-read Slot and byte-result dispatch on every return route");
            selected=state.stored;++returns;continue;
        }
        if(ins.mnemonic==ZYDIS_MNEMONIC_CALL) {
            uintptr_t candidate{};bool frameReader=false;
            // A byte is Slot only after a frame-owned argument read into its
            // actual destination, never just because it is a stack byte.
            const auto cx=state.r[reg(ZYDIS_REGISTER_RCX)],dx=state.r[reg(ZYDIS_REGISTER_RDX)],r8=state.r[reg(ZYDIS_REGISTER_R8)];
            if(cx.kind==Kind::Frame && dx.kind==Kind::FrameObject && r8.kind==Kind::StackAddress && !r8.uncertain && a.type==ZYDIS_OPERAND_TYPE_IMMEDIATE && a.imm.is_relative){
                if(!frameStep(relative(at,d)))throw std::runtime_error("Frame-owned Slot argument destination cannot be verified for the bytecode dispatch ABI");
                state.memory[r8.detail]={Kind::Slot};state.widths[r8.detail]=1;frameReader=true;
            }
            const bool indirectCopy=abi.propertyCopy && a.type==ZYDIS_OPERAND_TYPE_REGISTER && value(a).kind==Kind::PropertyCopy;
            const bool directCopy=abi.propertyCopy && a.type==ZYDIS_OPERAND_TYPE_IMMEDIATE && a.imm.is_relative && relative(at,d)==abi.propertyCopy;
            if(cx.kind==Kind::Property && dx.kind==Kind::StackAddress && !dx.uncertain && r8.kind==Kind::Locals){
                if(!indirectCopy && !directCopy)throw std::runtime_error("Frame-owned Slot argument destination cannot be verified for direct property copy");
                state.memory[dx.detail]={Kind::Slot};state.widths[dx.detail]=1;
            }
            if(state.r[reg(ZYDIS_REGISTER_RCX)].kind==Kind::Owner) {
                if(a.type==ZYDIS_OPERAND_TYPE_IMMEDIATE && a.imm.is_relative && state.r[reg(ZYDIS_REGISTER_RDX)].kind==Kind::Slot)candidate=at;
            }
            // Only an unclassified call can escape this Result pointer: the
            // recognized owner/Slot and argument-copy boundaries have known
            // arity/destination/read-only-source contracts. No callee body gate.
            if(state.stored && !candidate && !frameReader && !indirectCopy && !directCopy){
                for(int i:{1,2,8,9})if(state.r[i].kind==Kind::Result)state.stored=0;
                for(const auto& [offset,arg]:state.memory)if(offset>=state.stack+0x20 && arg.kind==Kind::Result)state.stored=0;
            }
            for(int i=0;i<16;++i)if(!nonvolatile(i))state.r[i]={};
            if(candidate) {
                if(state.call && state.call!=candidate)throw std::runtime_error("native wrapper has multiple operation targets");
                state.call=candidate;
                state.r[reg(ZYDIS_REGISTER_RAX)]={Kind::ByteResult,int64_t(candidate)};
            }
        } else {
            Value assigned{};bool assign=false;
            if((ins.mnemonic==ZYDIS_MNEMONIC_MOV||ins.mnemonic==ZYDIS_MNEMONIC_MOVZX) && a.type==ZYDIS_OPERAND_TYPE_REGISTER){assigned=value(b);assign=true;if((a.size!=64||b.size!=64) && assigned.kind!=Kind::Slot && assigned.kind!=Kind::ByteResult && assigned.kind!=Kind::Flags && assigned.kind!=Kind::Constant)assigned={};}
            if(ins.mnemonic==ZYDIS_MNEMONIC_XOR && a.type==ZYDIS_OPERAND_TYPE_REGISTER && b.type==ZYDIS_OPERAND_TYPE_REGISTER && a.reg.value==b.reg.value){assigned={Kind::Constant,0};assign=true;}
            for(unsigned i=0;i<ins.operand_count;++i)if(d.op[i].type==ZYDIS_OPERAND_TYPE_REGISTER && d.op[i].reg.value==ZYDIS_REGISTER_RFLAGS && (d.op[i].actions&ZYDIS_OPERAND_ACTION_MASK_WRITE)){state.outTest=false;state.copyEqual=-1;}
            if(ins.mnemonic==ZYDIS_MNEMONIC_CMP && abi.propertyCopy){
                if(value(a).kind==Kind::PropertyCopy && value(b).kind==Kind::Address)state.copyEqual=uintptr_t(value(b).detail)==abi.propertyCopy?1:0;
                if(value(b).kind==Kind::PropertyCopy && value(a).kind==Kind::Address)state.copyEqual=uintptr_t(value(a).detail)==abi.propertyCopy?1:0;
            }
            if(ins.mnemonic==ZYDIS_MNEMONIC_BT)state.outTest=value(a).kind==Kind::Flags && b.type==ZYDIS_OPERAND_TYPE_IMMEDIATE && b.imm.value.u==8;
            if(ins.mnemonic==ZYDIS_MNEMONIC_LEA && a.type==ZYDIS_OPERAND_TYPE_REGISTER && a.size==64 && b.type==ZYDIS_OPERAND_TYPE_MEMORY && b.mem.base==ZYDIS_REGISTER_RSP && b.mem.index==ZYDIS_REGISTER_NONE){assigned={Kind::StackAddress,state.stack+b.mem.disp.value};assign=true;}
            if(ins.mnemonic==ZYDIS_MNEMONIC_LEA && a.type==ZYDIS_OPERAND_TYPE_REGISTER && a.size==64 && b.type==ZYDIS_OPERAND_TYPE_MEMORY){
                if(b.mem.base==ZYDIS_REGISTER_RSP){assigned=resultAlias({Kind::StackAddress,state.stack},b.mem.disp.value,b.mem.index!=ZYDIS_REGISTER_NONE);assign=true;}
                const int base=reg(b.mem.base);if(base>=0 && (state.r[base].kind==Kind::Result||state.r[base].kind==Kind::StackAddress)){assigned=resultAlias(state.r[base],b.mem.disp.value,b.mem.index!=ZYDIS_REGISTER_NONE);assign=true;}
            }
            if(a.type==ZYDIS_OPERAND_TYPE_REGISTER && a.size==64 && (value(a).kind==Kind::Result||value(a).kind==Kind::StackAddress)){
                if((ins.mnemonic==ZYDIS_MNEMONIC_ADD||ins.mnemonic==ZYDIS_MNEMONIC_SUB) && b.type==ZYDIS_OPERAND_TYPE_IMMEDIATE && b.imm.value.s!=(std::numeric_limits<int64_t>::min)()){
                    assigned=resultAlias(value(a),ins.mnemonic==ZYDIS_MNEMONIC_ADD?b.imm.value.s:-b.imm.value.s);assign=true;
                }
                if(ins.mnemonic==ZYDIS_MNEMONIC_INC||ins.mnemonic==ZYDIS_MNEMONIC_DEC){assigned=resultAlias(value(a),ins.mnemonic==ZYDIS_MNEMONIC_INC?1:-1);assign=true;}
            }
            const auto storedValue=value(b); // Sample before invalidating aliases.
            for(unsigned i=0;i<ins.operand_count;++i){const auto& o=d.op[i];
                if(o.type!=ZYDIS_OPERAND_TYPE_MEMORY || !(o.actions&ZYDIS_OPERAND_ACTION_MASK_WRITE))continue;
                const int base=reg(o.mem.base);bool stackAddress=o.mem.base==ZYDIS_REGISTER_RSP;
                int64_t start=state.stack;
                if(!stackAddress && base>=0 && state.r[base].kind==Kind::StackAddress){stackAddress=true;start=state.r[base].detail;}
                if(!stackAddress)continue;
                const auto address=resultAlias({Kind::StackAddress,start,base>=0 && state.r[base].uncertain},o.mem.disp.value,o.mem.index!=ZYDIS_REGISTER_NONE);
                const int64_t bytes=(o.size+7)/8;
                for(auto it=state.memory.begin();it!=state.memory.end();){
                    const auto factStart=it->first;const int64_t factBytes=state.widths.at(factStart);
                    const bool overlaps=address.uncertain || !bytes || (ins.attributes&(ZYDIS_ATTRIB_HAS_REP|ZYDIS_ATTRIB_HAS_REPE|ZYDIS_ATTRIB_HAS_REPNE)) || (address.detail<factStart+factBytes && factStart<address.detail+bytes);
                    if(overlaps){state.widths.erase(factStart);it=state.memory.erase(it);}else ++it;
                }
            }
            if(ins.mnemonic==ZYDIS_MNEMONIC_MOV && a.type==ZYDIS_OPERAND_TYPE_MEMORY && a.mem.index==ZYDIS_REGISTER_NONE){
                const int base=reg(a.mem.base);bool stackAddress=a.mem.base==ZYDIS_REGISTER_RSP;int64_t start=state.stack;
                if(!stackAddress && base>=0 && state.r[base].kind==Kind::StackAddress){stackAddress=true;start=state.r[base].detail;}
                if(stackAddress){const auto address=resultAlias({Kind::StackAddress,start,base>=0 && state.r[base].uncertain},a.mem.disp.value);
                    if(!address.uncertain){state.memory[address.detail]=storedValue;state.widths[address.detail]=(a.size+7)/8;}
                }
            }
            if(ins.mnemonic==ZYDIS_MNEMONIC_MOV && a.type==ZYDIS_OPERAND_TYPE_REGISTER && b.type==ZYDIS_OPERAND_TYPE_REGISTER && b.reg.value==ZYDIS_REGISTER_RSP && a.size==64){assigned={Kind::StackAddress,state.stack};assign=true;}
            if(ins.mnemonic==ZYDIS_MNEMONIC_LEA && a.type==ZYDIS_OPERAND_TYPE_REGISTER && a.size==64 && b.type==ZYDIS_OPERAND_TYPE_MEMORY && b.mem.base==ZYDIS_REGISTER_RIP){assigned={Kind::Address,int64_t(relative(at,d,1))};assign=true;}
            if(a.type==ZYDIS_OPERAND_TYPE_MEMORY && a.mem.index==ZYDIS_REGISTER_NONE && a.mem.disp.value==0) {
                const auto base=reg(a.mem.base);
                if(base>=0 && state.r[base].kind==Kind::Result && state.r[base].detail==0 && !state.r[base].uncertain) {
                    const bool byte=ins.mnemonic==ZYDIS_MNEMONIC_MOV && a.size==8 && b.type==ZYDIS_OPERAND_TYPE_REGISTER && b.reg.value==ZYDIS_REGISTER_AL && value(b).kind==Kind::ByteResult;
                    if(state.call && byte)state.stored=state.call;
                }
            }
            if(assign && a.type==ZYDIS_OPERAND_TYPE_REGISTER && a.size<32){const int dest=reg(a.reg.value);if(dest>=0 && (state.r[dest].kind==Kind::Result||state.r[dest].kind==Kind::StackAddress)){assigned=state.r[dest];assigned.uncertain=true;}}
            // Register writes that do not carry a proven value invalidate it.
            for(unsigned i=0;i<ins.operand_count;++i) {
                const auto& o=d.op[i];if(o.type!=ZYDIS_OPERAND_TYPE_REGISTER || !(o.actions&ZYDIS_OPERAND_ACTION_MASK_WRITE))continue;
                const auto r=reg(o.reg.value);if(r>=0 && r!=reg(ZYDIS_REGISTER_RSP)){
                    if((state.r[r].kind==Kind::Result||state.r[r].kind==Kind::StackAddress) && !assign)state.r[r].uncertain=true;
                    else if(!highByte(o.reg.value)||(state.r[r].kind!=Kind::Slot&&state.r[r].kind!=Kind::ByteResult))state.r[r]={};
                }
            }
            if(assign && !highByte(a.reg.value)){const auto r=reg(a.reg.value);if(r>=0)state.r[r]=assigned;}
            if(ins.mnemonic==ZYDIS_MNEMONIC_PUSH)state.stack-=8;
            if(ins.mnemonic==ZYDIS_MNEMONIC_POP)state.stack+=8;
            if((ins.mnemonic==ZYDIS_MNEMONIC_SUB||ins.mnemonic==ZYDIS_MNEMONIC_ADD) && a.type==ZYDIS_OPERAND_TYPE_REGISTER && a.reg.value==ZYDIS_REGISTER_RSP && b.type==ZYDIS_OPERAND_TYPE_IMMEDIATE)
                state.stack+=(ins.mnemonic==ZYDIS_MNEMONIC_ADD?1:-1)*b.imm.value.s;
            else if(a.type==ZYDIS_OPERAND_TYPE_REGISTER && a.reg.value==ZYDIS_REGISTER_RSP && (a.actions&ZYDIS_OPERAND_ACTION_MASK_WRITE) && ins.mnemonic!=ZYDIS_MNEMONIC_POP)
                throw std::runtime_error("native wrapper stack convention cannot be verified");
        }
        if(ins.meta.category==ZYDIS_CATEGORY_COND_BR || ins.mnemonic==ZYDIS_MNEMONIC_JMP) {
            if(a.type!=ZYDIS_OPERAND_TYPE_IMMEDIATE || !a.imm.is_relative)throw std::runtime_error("native wrapper has an unresolved branch");
            if((ins.mnemonic==ZYDIS_MNEMONIC_JNZ||ins.mnemonic==ZYDIS_MNEMONIC_JZ) && state.copyEqual>=0){
                // The actual reflected Slot property supplies this virtual entry.
                // A specialization for another property class is not reachable.
                const bool take=ins.mnemonic==ZYDIS_MNEMONIC_JZ?state.copyEqual==1:state.copyEqual==0;
                enqueue(take?relative(at,d):next,state);continue;
            }
            if(state.outTest && ins.mnemonic==ZYDIS_MNEMONIC_JNB) {
                // Slot is reflected as an input, not an OutParm. The frame's
                // first compiled-in property is this one Slot argument.
                state.outTest=false;enqueue(relative(at,d),state);continue;
            }
            state.outTest=false;
            enqueue(relative(at,d),state);
            if(ins.mnemonic==ZYDIS_MNEMONIC_JMP)continue;
        }
        enqueue(next,state);
    }
    if(!returns || !selected)throw std::runtime_error("native wrapper required dispatch/result route is missing");
        auto d=decode(selected);const auto target=relative(selected,d);
    if(!accessible(reinterpret_cast<void*>(target),1,true))throw std::runtime_error("item-use target is not readable executable code");
    return {target,0};
}
}

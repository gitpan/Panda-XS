#include <map>
#include <string>
#include <stdexcept>
#include <xs/xs.h>

namespace xs {

using std::invalid_argument;

payload_marker_t sv_payload_default_marker;
std::map<std::string, payload_marker_t> sv_class_markers;

const int CVf_NEXT_WRAPPER_CREATED = 0x10000000;

payload_marker_t* sv_payload_marker (const char* class_name) {
    if (!class_name[0]) return &sv_payload_default_marker;
    return &sv_class_markers[class_name];
}

static SV* _next_create_wrapper (CV* cv, next_t type) {
    CvFLAGS(cv) |= CVf_NEXT_WRAPPER_CREATED;
    GV* gv = CvGV(cv);
    HV* stash = GvSTASH(gv);
    std::string name = GvNAME(gv);
    std::string stashname = HvNAME(stash);
    std::string origxs = "_xs_orig_" + name;
    std::string next_code;
    switch (type) {
        case NEXT_SUPER:  next_code = "shift->SUPER::" + name; break;
        case NEXT_METHOD: next_code = "next::method"; break;
        case NEXT_MAYBE:  next_code = "maybe::next::method"; break;
    }
    if (!next_code.length()) throw new invalid_argument("type");
    std::string code =
        "package " + stashname + ";\n" +
        "use feature 'state';\n" +
        "no warnings 'redefine';\n" +
        "BEGIN { *" + origxs + " = \\&" + name + "; }\n" +
        "sub " + name + " {\n" +
        "    eval q!sub " + name + " { " + origxs + "(@_) } !;\n" +
        "    " + next_code + "(@_);\n" +
        "}\n" +
        "\\&" + name;
    return eval_pv(code.c_str(), 1);
}

SV* call_next (CV* cv, SV** args, I32 items, next_t type, I32 flags) {
    SV* ret = NULL;
    if (CvFLAGS(cv) & CVf_NEXT_WRAPPER_CREATED) { // ensure module has a perl wrapper for cv
        dSP; ENTER; SAVETMPS;
        PUSHMARK(SP);
        for (I32 i = 0; i < items; ++i) XPUSHs(*args++);
        PUTBACK;
        int count;
        if (type == NEXT_SUPER) {
            GV* gv = CvGV(cv);
            GV* supergv = gv_fetchmethod_pvn_flags(
                GvSTASH(gv), GvNAME(gv), GvNAMELEN(gv), GV_CROAK|GV_SUPER|(GvNAMEUTF8(gv) ? SVf_UTF8 : 0)
            );
            count = call_sv((SV*)GvCV(supergv), flags|G_SCALAR);
        } else {
            count = call_method(type == NEXT_METHOD ? "next::method" : "maybe::next::method", flags|G_SCALAR);
        }
        SPAGAIN;
        while (count--) ret = POPs;
        SvREFCNT_inc_simple(ret);
        PUTBACK;
        FREETMPS; LEAVE;
    }
    else {
        SV* wrapper = _next_create_wrapper(cv, type);
        dSP; ENTER; SAVETMPS;
        PUSHMARK(SP);
        for (I32 i = 0; i < items; ++i) XPUSHs(*args++);
        PUTBACK;
        int count = call_sv(wrapper, flags|G_SCALAR);
        SPAGAIN;
        while (count--) ret = POPs;
        SvREFCNT_inc_simple_void(ret);
        PUTBACK;
        FREETMPS; LEAVE;
    }

    return ret;
}

SV* _typemap_out_oext (SV* obase, void* var, SV* CLASS_SV, const char* CLASS, payload_marker_t* marker) {
    if (!var) return &PL_sv_undef;
    SV* objrv;
    if (obase) {
        if (SvROK(obase)) {
            objrv = obase;
            obase = SvRV(obase);
        }
        else {
            objrv = newRV_noinc(obase);
            sv_bless(objrv, CLASS_SV ? gv_stashsv(CLASS_SV, GV_ADD) : gv_stashpvn(CLASS, strlen(CLASS), GV_ADD));
        }
    } else {
        obase = newSV(0);
        objrv = newRV_noinc(obase);
        sv_bless(objrv, CLASS_SV ? gv_stashsv(CLASS_SV, GV_ADD) : gv_stashpvn(CLASS, strlen(CLASS), GV_ADD));
    }

    sv_payload_attach(obase, var, marker);

    return objrv;
}

};

#pragma once

extern "C" {
#  include "EXTERN.h"
#  include "perl.h"
#  include "XSUB.h"
}
#include "ppport.h"

typedef SV OSV;
typedef HV OHV;
typedef AV OAV;
typedef IO OIO;

namespace xs {

enum next_t {
    NEXT_SUPER  = 0,
    NEXT_METHOD = 1,
    NEXT_MAYBE  = 2
};

typedef MGVTBL payload_marker_t;
extern payload_marker_t sv_payload_default_marker;
payload_marker_t* sv_payload_marker (const char* class_name);

inline void sv_payload_attach (SV* sv, void* ptr, const payload_marker_t* marker = &sv_payload_default_marker) {
    sv_magicext(sv, NULL, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker, (const char*) ptr, 0);
    SvRMAGICAL_off(sv); // remove unnecessary perfomance overheat
}

inline bool sv_payload_exists (const SV* sv, const payload_marker_t* marker) {
    if (SvTYPE(sv) < SVt_PVMG) return false;
    return mg_findext(sv, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker) != NULL;
}

inline void* sv_payload (const SV* sv, const payload_marker_t* marker) {
    if (SvTYPE(sv) < SVt_PVMG) return NULL;
    MAGIC* mg = mg_findext(sv, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker);
    return mg ? mg->mg_ptr : NULL;
}

inline int sv_payload_detach (SV* sv, payload_marker_t* marker) {
    if (SvTYPE(sv) < SVt_PVMG) return 0;
    return sv_unmagicext(sv, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker);
}

inline void rv_payload_attach (const SV* rv, void* ptr, const payload_marker_t* marker = NULL) {
    sv_payload_attach(SvRV(rv), ptr, marker);
}

inline bool rv_payload_exists (const SV* rv, const payload_marker_t* marker = NULL) {
    return sv_payload_exists(SvRV(rv), marker);
}

inline void* rv_payload (const SV* rv, const payload_marker_t* marker = NULL) {
    return sv_payload(SvRV(rv), marker);
}

inline int rv_payload_detach (const SV* rv, payload_marker_t* marker = NULL) {
    return sv_payload_detach(SvRV(rv), marker);
}


inline SV* typemap_out_ref (SV* var) {
    return var ? newRV_noinc(var) : &PL_sv_undef;
}

inline SV* typemap_out_oref (SV* var, HV* CLASS) {
    return var ? sv_bless(newRV_noinc(var), CLASS) : &PL_sv_undef;
}
inline SV* typemap_out_oref (SV* var, const char* CLASS) {
    return typemap_out_oref(var, gv_stashpvn(CLASS, strlen(CLASS), GV_ADD));
}
inline SV* typemap_out_oref (SV* var, SV* CLASS) {
    return typemap_out_oref(var, gv_stashsv(CLASS, GV_ADD));
}

inline SV* typemap_out_optr (void* var, HV* CLASS) {
    return var ? sv_bless(newRV_noinc(newSViv((IV)var)), CLASS) : &PL_sv_undef;
}
inline SV* typemap_out_optr (void* var, const char* CLASS) {
    return typemap_out_optr(var, gv_stashpvn(CLASS, strlen(CLASS), GV_ADD));
}
inline SV* typemap_out_optr (void* var, SV* CLASS) {
    return typemap_out_optr(var, gv_stashsv(CLASS, GV_ADD));
}

SV* _typemap_out_oext (SV* self, void* var, HV* stash, SV* CLASS_SV, const char* CLASS, payload_marker_t* marker);
inline SV* typemap_out_oext (SV* self, void* var, HV* CLASS, payload_marker_t* marker = NULL) {
    return _typemap_out_oext(self, var, CLASS, NULL, NULL, marker);
}
inline SV* typemap_out_oext (SV* self, void* var, const char* CLASS, payload_marker_t* marker = NULL) {
    return _typemap_out_oext(self, var, NULL, NULL, CLASS, marker);
}
inline SV* typemap_out_oext (SV* self, void* var, SV* CLASS, payload_marker_t* marker = NULL) {
    return _typemap_out_oext(self, var, NULL, CLASS, NULL, marker);
}

inline AV* typemap_in_av (SV* arg) {
    if (SvROK(arg) && (SvTYPE(SvRV(arg)) == SVt_PVAV)) return (AV*)SvRV(arg);
    return NULL;
}

inline HV* typemap_in_hv (SV* arg) {
    if (SvROK(arg) && (SvTYPE(SvRV(arg)) == SVt_PVHV)) return (HV*)SvRV(arg);
    return NULL;
}

inline IO* typemap_in_io (SV* arg) {
    if (SvROK(arg) && (SvTYPE(SvRV(arg)) == SVt_PVIO)) return (IO*)SvRV(arg);
    return NULL;
}

inline CV* typemap_in_cv (SV* arg) {
    if (SvROK(arg) && (SvTYPE(SvRV(arg)) == SVt_PVCV)) return (CV*)SvRV(arg);
    return NULL;
}

inline SV* typemap_in_osv (SV* arg) {
    if (sv_isobject(arg) && SvTYPE(SvRV(arg)) <= SVt_PVMG) return (SV*)SvRV(arg);
    return NULL;
}

inline AV* typemap_in_oav (SV* arg) {
    if (sv_isobject(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) return (AV*)SvRV(arg);
    return NULL;
}

inline HV* typemap_in_ohv (SV* arg) {
    if (sv_isobject(arg) && SvTYPE(SvRV(arg)) == SVt_PVHV) return (HV*)SvRV(arg);
    return NULL;
}

inline IO* typemap_in_oio (SV* arg) {
    if (sv_isobject(arg) && SvTYPE(SvRV(arg)) == SVt_PVIO) return (IO*)SvRV(arg);
    return NULL;
}

inline void* typemap_in_optr (SV* arg) {
    if (sv_isobject(arg) && SvTYPE(SvRV(arg)) == SVt_PVMG) return (void*)SvIV((SV*)SvRV(arg));
    return NULL;
}

inline void* typemap_in_oext (SV* arg, payload_marker_t* marker = NULL) {
    void* ret;
    if (!SvROK(arg) || !(ret = xs::rv_payload(arg, marker))) return NULL;
    return ret;
}

SV* call_next (CV* cv, SV** args, I32 items, next_t type, I32 flags = 0);
inline SV* call_super       (CV* cv, SV** args, I32 items, I32 flags = 0) { return call_next(cv, args, items, NEXT_SUPER, flags); }
inline SV* call_next_method (CV* cv, SV** args, I32 items, I32 flags = 0) { return call_next(cv, args, items, NEXT_METHOD, flags); }
inline SV* call_next_maybe  (CV* cv, SV** args, I32 items, I32 flags = 0) { return call_next(cv, args, items, NEXT_MAYBE, flags); }

};

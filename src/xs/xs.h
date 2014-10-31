#pragma once

extern "C" {
#  include "EXTERN.h"
#  include "perl.h"
#  include "XSUB.h"
}
#include "ppport.h"

// detect C++11 most feature-capable compiler
#if __cplusplus >= 201103L
#  define CPP11X
#endif

#include <panda/refcnt.h>

typedef SV OSV;
typedef HV OHV;
typedef AV OAV;
typedef IO OIO;

#ifndef hv_storehek
#  define hv_storehek(hv, hek, val) \
    hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), HV_FETCH_ISSTORE|HV_FETCH_JUST_SV, (val), HEK_HASH(hek))
#  define hv_fetchhek(hv, hek, lval) \
    ((SV**)hv_common( \
        (hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), (lval) ? (HV_FETCH_JUST_SV|HV_FETCH_LVALUE) : HV_FETCH_JUST_SV, NULL, HEK_HASH(hek) \
    ))
#  define hv_deletehek(hv, hek, flags) \
    hv_common((hv), NULL, HEK_KEY(hek), HEK_LEN(hek), HEK_UTF8(hek), (flags)|HV_DELETE, NULL, HEK_HASH(hek))
#endif

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

inline void sv_payload_attach (SV* sv, void* ptr, SV* obj, const payload_marker_t* marker = &sv_payload_default_marker) {
    MAGIC* mg = sv_magicext(sv, obj, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker, (const char*) ptr, 0);
    mg->mg_flags |= MGf_REFCOUNTED;
    SvRMAGICAL_off(sv); // remove unnecessary perfomance overheat
}

inline void sv_payload_attach (SV* sv, SV* obj, const payload_marker_t* marker = &sv_payload_default_marker) {
    sv_payload_attach(sv, NULL, obj, marker);
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

inline SV* sv_payload_sv (const SV* sv, const payload_marker_t* marker) {
    if (SvTYPE(sv) < SVt_PVMG) return NULL;
    MAGIC* mg = mg_findext(sv, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker);
    return mg ? mg->mg_obj : NULL;
}

inline int sv_payload_detach (SV* sv, payload_marker_t* marker) {
    if (SvTYPE(sv) < SVt_PVMG) return 0;
    return sv_unmagicext(sv, PERL_MAGIC_ext, marker ? marker : &sv_payload_default_marker);
}

inline void rv_payload_attach (const SV* rv, void* ptr, const payload_marker_t* marker = NULL) {
    sv_payload_attach(SvRV(rv), ptr, marker);
}

inline void rv_payload_attach (const SV* rv, void* ptr, SV* obj, const payload_marker_t* marker = NULL) {
    sv_payload_attach(SvRV(rv), ptr, obj, marker);
}

inline void rv_payload_attach (const SV* rv, SV* obj, const payload_marker_t* marker = NULL) {
    sv_payload_attach(SvRV(rv), obj, marker);
}

inline bool rv_payload_exists (const SV* rv, const payload_marker_t* marker = NULL) {
    return sv_payload_exists(SvRV(rv), marker);
}

inline void* rv_payload (const SV* rv, const payload_marker_t* marker = NULL) {
    return sv_payload(SvRV(rv), marker);
}

inline SV* rv_payload_sv (const SV* rv, const payload_marker_t* marker = NULL) {
    return sv_payload_sv(SvRV(rv), marker);
}

inline int rv_payload_detach (const SV* rv, payload_marker_t* marker = NULL) {
    return sv_payload_detach(SvRV(rv), marker);
}

inline SV* _typemap_out_oref (SV* var, HV* CLASS) {
    return var ? sv_bless(newRV_noinc(var), CLASS) : &PL_sv_undef;
}
inline SV* _typemap_out_oref (SV* var, const char* CLASS) {
    return _typemap_out_oref(var, gv_stashpvn(CLASS, strlen(CLASS), GV_ADD));
}
inline SV* _typemap_out_oref (SV* var, SV* CLASS) {
    return _typemap_out_oref(var, gv_stashsv(CLASS, GV_ADD));
}

inline SV* _typemap_out_optr (void* var, HV* CLASS) {
    return var ? sv_bless(newRV_noinc(newSViv((IV)var)), CLASS) : &PL_sv_undef;
}
inline SV* _typemap_out_optr (void* var, const char* CLASS) {
    return _typemap_out_optr(var, gv_stashpvn(CLASS, strlen(CLASS), GV_ADD));
}
inline SV* _typemap_out_optr (void* var, SV* CLASS) {
    return _typemap_out_optr(var, gv_stashsv(CLASS, GV_ADD));
}

template <class T, typename C>
inline SV* _typemap_out_optr (const panda::shared_ptr<T, true> &sp, C CLASS) {
     sp->retain();
     return _typemap_out_optr(sp.get(), CLASS);
}

template <class T, typename C>
inline SV* _typemap_out_optr (const panda::shared_ptr<T, false> &sp, C CLASS) {
    return _typemap_out_optr(new panda::shared_ptr<T>(sp), CLASS);
}

#ifdef CPP11X
template <class T, typename C>
inline SV* _typemap_out_optr (const std::shared_ptr<T> &sp, C CLASS) {
    return _typemap_out_optr(new std::shared_ptr<T>(sp), CLASS);
}
#endif

SV* _typemap_out_oext (SV* self, void* var, HV* CLASS, payload_marker_t* marker = NULL);
SV* _typemap_out_oext (SV* self, void* var, SV* CLASS, payload_marker_t* marker = NULL);
SV* _typemap_out_oext (SV* self, void* var, const char* CLASS, payload_marker_t* marker = NULL);

template <class T, typename C>
inline SV* _typemap_out_oext (SV* self, const panda::shared_ptr<T, true> &sp, C CLASS, payload_marker_t* marker = NULL) {
     sp->retain();
     return _typemap_out_oext(self, sp.get(), CLASS, marker);
}

template <class T, typename C>
inline SV* _typemap_out_oext (SV* self, const panda::shared_ptr<T, false> &sp, C CLASS, payload_marker_t* marker = NULL) {
    return _typemap_out_oext(self, new panda::shared_ptr<T>(sp), CLASS, marker);
}

#ifdef CPP11X
template <class T, typename C>
inline SV* _typemap_out_oext (SV* self, const std::shared_ptr<T> &sp, C CLASS, payload_marker_t* marker = NULL) {
    return _typemap_out_oext(self, new std::shared_ptr<T>(sp), CLASS, marker);
}
#endif

template <class T>
inline void _typemap_in_optr (SV* arg, T* varptr) {
    if (sv_isobject(arg)) {
        SV* obj = SvRV(arg);
        if (SvIOK(obj)) {
            *varptr = static_cast<T>((void*)SvIVX(obj));
            return;
        }
    }
    *varptr = NULL;
}

template <class T>
inline void _typemap_in_optr (SV* arg, panda::shared_ptr<T,true>* sptr, bool destroy = false) {
    void* ptr;
    _typemap_in_optr(arg, &ptr);
    *sptr = static_cast<T*>(ptr);
    if (destroy) static_cast<T*>(ptr)->release();
}

template <class T>
inline void _typemap_in_optr (SV* arg, panda::shared_ptr<T,false>* sptr, bool destroy = false) {
    void* ptr;
    _typemap_in_optr(arg, &ptr);
    *sptr = *(static_cast<panda::shared_ptr<T,false>*>(ptr));
    if (destroy) delete static_cast<panda::shared_ptr<T,false>*>(ptr);
}

#ifdef CPP11X
template <class T>
inline void _typemap_in_optr (SV* arg, std::shared_ptr<T>* sptr, bool destroy = false) {
    void* ptr;
    _typemap_in_optr(arg, &ptr);
    *sptr = *(static_cast<std::shared_ptr<T>*>(ptr));
    if (destroy) delete static_cast<std::shared_ptr<T>*>(ptr);
}
#endif

template <class T>
inline void _typemap_in_oext (SV* arg, T* varptr, payload_marker_t* marker = NULL) {
    if (SvROK(arg)) *varptr = static_cast<T>(rv_payload(arg, marker));
    else *varptr = NULL;
}

template <class T>
inline void _typemap_in_oext (SV* arg, panda::shared_ptr<T,true>* sptr, payload_marker_t* marker = NULL, bool destroy = false) {
    void* ptr;
    _typemap_in_oext(arg, &ptr, marker);
    *sptr = static_cast<T*>(ptr);
    if (destroy) static_cast<T*>(ptr)->release();
}

template <class T>
inline void _typemap_in_oext (SV* arg, panda::shared_ptr<T,false>* sptr, payload_marker_t* marker = NULL, bool destroy = false) {
    void* ptr;
    _typemap_in_oext(arg, &ptr, marker);
    *sptr = *(static_cast<panda::shared_ptr<T,false>*>(ptr));
    if (destroy) delete static_cast<panda::shared_ptr<T,false>*>(ptr);
}

#ifdef CPP11X
template <class T>
inline void _typemap_in_oext (SV* arg, std::shared_ptr<T>* sptr, payload_marker_t* marker = NULL, bool destroy = false) {
    void* ptr;
    _typemap_in_oext(arg, &ptr, marker);
    *sptr = *(static_cast<std::shared_ptr<T>*>(ptr));
    if (destroy) delete static_cast<std::shared_ptr<T>*>(ptr);
}
#endif

SV* call_next (CV* cv, SV** args, I32 items, next_t type, I32 flags = 0);
inline SV* call_super       (CV* cv, SV** args, I32 items, I32 flags = 0) { return call_next(cv, args, items, NEXT_SUPER, flags); }
inline SV* call_next_method (CV* cv, SV** args, I32 items, I32 flags = 0) { return call_next(cv, args, items, NEXT_METHOD, flags); }
inline SV* call_next_maybe  (CV* cv, SV** args, I32 items, I32 flags = 0) { return call_next(cv, args, items, NEXT_MAYBE, flags); }

};

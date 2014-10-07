#include <xs/xs.h>
using xs::payload_marker_t;

STATIC payload_marker_t marker;

#ifdef TEST_FULL
XS_EXTERNAL(boot_Panda__XS__Test);
#endif

MODULE = Panda::XS                PACKAGE = Panda::XS
PROTOTYPES: DISABLE

void sv_payload_attach (SV* sv, SV* payload) {
    SvUPGRADE(sv, SVt_PVMG);
    sv_unmagicext(sv, PERL_MAGIC_ext, &marker);
    MAGIC* mg = sv_magicext(sv, payload, PERL_MAGIC_ext, &marker, NULL, 0);
    mg->mg_flags |= MGf_REFCOUNTED;
}    
    
bool sv_payload_exists (SV* sv) {
    if (SvTYPE(sv) < SVt_PVMG) XSRETURN_UNDEF;
    RETVAL = mg_findext(sv, PERL_MAGIC_ext, &marker) != NULL;
}   
    
SV* sv_payload (SV* sv) {
    if (SvTYPE(sv) < SVt_PVMG) XSRETURN_UNDEF;
    MAGIC* mg = mg_findext(sv, PERL_MAGIC_ext, &marker);
    if (!mg) XSRETURN_UNDEF;
    RETVAL = mg->mg_obj;
    SvREFCNT_inc(RETVAL);
}    

int sv_payload_detach (SV* sv) {
    RETVAL = 0;
    if (SvTYPE(sv) < SVt_PVMG) XSRETURN(1);
    RETVAL = sv_unmagicext(sv, PERL_MAGIC_ext, &marker);
}

void obj2hv (SV* rv) {
    if (!SvROK(rv)) croak("Panda::XS::obj2hv: argument is not a reference");
    SV* obj = SvRV(rv);
    if (SvOK(obj)) {
        if (SvPOK(obj)) sv_setpv(obj, NULL);
        else SvOK_off(obj);
    }
    SvUPGRADE(obj, SVt_PVHV);
}

void obj2av (SV* rv) {
    if (!SvROK(rv)) croak("Panda::XS::obj2av: argument is not a reference");
    SV* obj = SvRV(rv);
    if (SvOK(obj)) {
        if (SvPOK(obj)) sv_setpv(obj, NULL);
        else SvOK_off(obj);
    }
    SvUPGRADE(obj, SVt_PVAV);
}

BOOT {
#ifdef TEST_FULL
    boot_Panda__XS__Test(aTHX_ cv);
#endif
}
    
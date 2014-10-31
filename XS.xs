#include <xs/xs.h>

STATIC xs::payload_marker_t marker;

#ifdef TEST_FULL
XS_EXTERNAL(boot_Panda__XS__Test);
#endif

MODULE = Panda::XS                PACKAGE = Panda::XS
PROTOTYPES: DISABLE

void sv_payload_attach (SV* sv, SV* payload) {
    xs::sv_payload_detach(sv, &marker);
    xs::sv_payload_attach(sv, payload, &marker);
}    
    
bool sv_payload_exists (SV* sv) {
    RETVAL = xs::sv_payload_exists(sv, &marker);
}   
    
SV* sv_payload (SV* sv) {
    RETVAL = xs::sv_payload_sv(sv, &marker);
    if (!RETVAL) XSRETURN_UNDEF;
    else SvREFCNT_inc_simple_void_NN(RETVAL);
}    

int sv_payload_detach (SV* sv) {
    RETVAL = xs::sv_payload_detach(sv, &marker);
}

void obj2hv (SV* rv) {
    if (!SvROK(rv)) croak("Panda::XS::obj2hv: argument is not a reference");
    SV* obj = SvRV(rv);
    if (SvOK(obj)) croak("Panda::XS::obj2hv: only references to undefs can be upgraded");
    SvUPGRADE(obj, SVt_PVHV);
}

void obj2av (SV* rv) {
    if (!SvROK(rv)) croak("Panda::XS::obj2av: argument is not a reference");
    SV* obj = SvRV(rv);
    if (SvOK(obj)) croak("Panda::XS::obj2av: only references to undefs can be upgraded");
    SvUPGRADE(obj, SVt_PVAV);
}

BOOT {
#ifdef TEST_FULL
    boot_Panda__XS__Test(aTHX_ cv);
#endif
}
    

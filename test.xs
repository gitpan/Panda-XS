#include <xs/xs.h>

static int dcnt = 0;

static AV* clone_array (AV* av, AV* to = NULL) {
    if (!av) return NULL;
    if (!to) to = newAV();
    SV** list = AvARRAY(av);
    for (I32 i = 0; i <= AvFILLp(av); ++i) {
        SV* val = *list++;
        if (!val) continue;
        SvREFCNT_inc(val);
        av_push(to, val);
    }
    return to;
}

static HV* clone_hash (HV* hv, HV* to = NULL) {
    if (!hv) return NULL;
    if (!to) to = newHV();
    HE** list = HvARRAY(hv);
    STRLEN hvmax = HvMAX(hv);
    if (!list) return to;
    for (STRLEN i = 0; i <= hvmax; ++i) {
        for (HE* entry = list[i]; entry; entry = HeNEXT(entry)) {
            SV* val = HeVAL(entry);
            SvREFCNT_inc(val);
            hv_store(to, HeKEY(entry), HeKLEN(entry), val, HeHASH(entry));
        }
    }
    return to;
}

class MyBase {
    public:
    int val;
    MyBase (int arg) : val(arg) {}
    virtual ~MyBase () { dcnt++; }
};

class MyChild : public MyBase {
    public:
    int val2;
    MyChild (int arg1, int arg2) : val2(arg2), MyBase(arg1) {}
    virtual ~MyChild () { dcnt++; }
};

class MyOther {
    public:
    int val;
    MyOther (int arg) : val(arg) {}
    virtual ~MyOther () { dcnt++; }
};

class MixBase {
    public:
    int val;
    MixBase (int arg) : val(arg) {}
    virtual ~MixBase () { dcnt++; }
};

class MixPluginA {
    public:
    int val;
    MixPluginA () : val(0) {}
    virtual ~MixPluginA () { dcnt++; }
};

class MixPluginB {
    public:
    int val;
    MixPluginB () : val(0) {}
    virtual ~MixPluginB () { dcnt++; }
};

class Wrapper {
    public:
    MyBase* obj;
    int xval;
    Wrapper (MyBase* arg) : obj(arg), xval(0) {}
    ~Wrapper () {
        dcnt++;
        delete obj;
    }
};

typedef MyBase  MyOPTR;
typedef MyChild MyOPTRChild;
typedef MyBase  Wrapped;
typedef MyBase  MyBaseAV;
typedef MyBase  MyBaseHV;

MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test
PROTOTYPES: DISABLE

int8_t i8 (int8_t val) {
    RETVAL = val;
}

int16_t i16 (int16_t val) {
    RETVAL = val;
}

int32_t i32 (int32_t val) {
    RETVAL = val;
}

int64_t i64 (int64_t val) {
    RETVAL = val;
}

uint8_t u8 (uint8_t val) {
    RETVAL = val;
}

uint16_t u16 (uint16_t val) {
    RETVAL = val;
}

uint32_t u32 (uint32_t val) {
    RETVAL = val;
}

uint64_t u64 (uint64_t val) {
    RETVAL = val;
}

time_t time_t (time_t val) {
    RETVAL = val;
}

AV* av_out (bool not_null = false) {
    RETVAL = not_null ? newAV() : NULL;
}

uint64_t av_in (AV* val) {
    RETVAL = (uint64_t)val;
}

HV* hv_out (bool not_null = false) {
    RETVAL = not_null ? newHV() : NULL;
}

uint64_t hv_in (HV* val) {
    RETVAL = (uint64_t)val;
}

IO* io_out (bool not_null = false) {
    if (not_null) {
        GV* gv = gv_fetchpv("STDOUT", 0, SVt_PVIO);
        RETVAL = GvIO(gv);
    }
    else RETVAL = NULL;
}

uint64_t io_in (IO* val) {
    RETVAL = (uint64_t)val;
}

CV* cv_out (bool not_null = false) {
    RETVAL = not_null ? cv : NULL;
}

uint64_t cv_in (CV* val) {
    RETVAL = (uint64_t)val;
}

int dcnt (SV* newval = NULL) {
    if (newval) dcnt = SvIV(newval);
    RETVAL = dcnt;
}

MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::OSV
PROTOTYPES: DISABLE

OSV* OSV::new (SV* strsv) {
    if (SvOK(strsv)) RETVAL = newSVpv(SvPV_nolen(strsv), 0);
    else RETVAL = NULL;
}

const char* OSV::get_val () {
    if (SvOK(THIS)) RETVAL = SvPV_nolen(THIS);
    else RETVAL = NULL;
}

void OSV::set_val (OSV* other) {
    if (other) {
        STRLEN len;
        const char* str = SvPV(other, len);
        sv_setpvn(THIS, str, len);
    }
    else SvOK_off(THIS);
}

OSV* OSV::clone () {
    const char* CLASS = HvNAME(SvSTASH(THIS));
    RETVAL = SvOK(THIS) ? newSVpvn(SvPVX(THIS), SvCUR(THIS)) : newSV(0);
}

MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::OAV
PROTOTYPES: DISABLE

OAV* OAV::new (AV* av) {
    if (av) RETVAL = clone_array(av);
    else RETVAL = NULL;
}

AV* OAV::get_val () {
    RETVAL = clone_array(THIS);
}

void OAV::set_val (OAV* other) {
    av_clear(THIS);
    clone_array(other, THIS);
}

OAV* OAV::clone () {
    const char* CLASS = HvNAME(SvSTASH(THIS));
    RETVAL = clone_array(THIS);
}

MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::OHV
PROTOTYPES: DISABLE

OHV* OHV::new (HV* hv) {
    if (hv) RETVAL = clone_hash(hv);
    else RETVAL = NULL;
}

HV* OHV::get_val () {
    RETVAL = clone_hash(THIS);
}

void OHV::set_val (OHV* other) {
    hv_clear(THIS);
    clone_hash(other, THIS);
}

OHV* OHV::clone () {
    const char* CLASS = HvNAME(SvSTASH(THIS));
    RETVAL = clone_hash(THIS);
}

MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::OIO
PROTOTYPES: DISABLE

OIO* OIO::new (IO* io) {
    RETVAL = io;
}

int OIO::get_val () {
    RETVAL = PerlIO_fileno(IoIFP(THIS));
}

void OIO::set_val (OIO* other) {
    if (!other) other = GvIO(gv_fetchpv("STDERR", 0, SVt_PVIO));
    IoIFP(THIS) = IoIFP(other);
}

OIO* OIO::clone () {
    const char* CLASS = HvNAME(SvSTASH(THIS));
    RETVAL = THIS;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::OPTR
PROTOTYPES: DISABLE

MyOPTR* MyOPTR::new (int arg) {
    if (arg) RETVAL = new MyOPTR(arg);
    else RETVAL = NULL;
}

int MyOPTR::val (SV* newval = NULL) {
    if (newval) THIS->val = SvIV(newval);
    RETVAL = THIS->val;
}

void MyOPTR::set_from (MyOPTR* other) {
    if (other) THIS->val = other->val;
}

void MyOPTR::DESTROY ()



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::OPTRChild
PROTOTYPES: DISABLE

MyOPTRChild* MyOPTRChild::new (int arg1, int arg2) {
    RETVAL = new MyOPTRChild(arg1, arg2);
}

int MyOPTRChild::val2 (SV* newval = NULL) {
    if (newval) THIS->val2 = SvIV(newval);
    RETVAL = THIS->val2;
}

void MyOPTRChild::set_from (MyOPTRChild* other) {
    if (other) {
        THIS->val = other->val;
        THIS->val2 = other->val2;
    }
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyBase
PROTOTYPES: DISABLE

MyBase* MyBase::new (int arg) {
    if (arg) RETVAL = new MyBase(arg);
    else RETVAL = NULL;
}

int MyBase::val (SV* newval = NULL) {
    if (newval) THIS->val = SvIV(newval);
    RETVAL = THIS->val;
}

void MyBase::set_from (MyBase* other) {
    if (other) THIS->val = other->val;
}

void MyBase::DESTROY ()



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyChild
PROTOTYPES: DISABLE

MyChild* MyChild::new (int arg1, int arg2) {
    if (arg1 || arg2) RETVAL = new MyChild(arg1, arg2);
    else RETVAL = NULL;
}

int MyChild::val2 (SV* newval = NULL) {
    if (newval) THIS->val2 = SvIV(newval);
    RETVAL = THIS->val2;
}

void MyChild::set_from (MyChild* other) {
    if (other) {
        THIS->val = other->val;
        THIS->val2 = other->val2;
    }
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyOther
PROTOTYPES: DISABLE

MyOther* MyOther::new (int arg1, int arg2) {
    self = xs::call_super(cv, &ST(0), items);
    if (SvOK(self)) RETVAL = new MyOther(arg1 + arg2);
    else RETVAL = NULL;
}

int MyOther::other_val (SV* newval = NULL) {
    if (newval) THIS->val = SvIV(newval);
    RETVAL = THIS->val;
}

void MyOther::set_from (MyOther* other) {
    xs::call_super(cv, &ST(0), items, G_DISCARD);
    if (other) THIS->val = other->val;
}

void MyOther::DESTROY () {
    xs::call_super(cv, &ST(0), items, G_DISCARD);
    delete THIS;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MixBase
PROTOTYPES: DISABLE

MixBase* MixBase::new (int arg) {
    if (arg) RETVAL = new MixBase(arg);
    else RETVAL = NULL;
}

int MixBase::val (SV* newval = NULL) {
    if (newval) THIS->val = SvIV(newval);
    RETVAL = THIS->val;
}

void MixBase::set_from (MixBase* other) {
    if (other) THIS->val = other->val;
}

void MixBase::DESTROY () {
    delete THIS;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MixPluginA
PROTOTYPES: DISABLE

MixPluginA* MixPluginA::new (int arg) {
    self = xs::call_next_method(cv, &ST(0), items);
    if (SvOK(self)) RETVAL = new MixPluginA();
    else RETVAL = NULL;
}

int MixPluginA::val_a (SV* newval = NULL) {
    if (newval) THIS->val = SvIV(newval);
    RETVAL = THIS->val;
}

void MixPluginA::set_from (MixPluginA* other) {
    xs::call_next_method(cv, &ST(0), items, G_DISCARD);
    if (other) THIS->val = other->val;
}

void MixPluginA::DESTROY () {
    xs::call_next_method(cv, &ST(0), items, G_DISCARD);
    delete THIS;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MixPluginB
PROTOTYPES: DISABLE

MixPluginB* MixPluginB::new (int arg) {
    self = xs::call_next_method(cv, &ST(0), items);
    if (SvOK(self)) RETVAL = new MixPluginB();
    else RETVAL = NULL;
}

int MixPluginB::val_b (SV* newval = NULL) {
    if (newval) THIS->val = SvIV(newval);
    RETVAL = THIS->val;
}

void MixPluginB::set_from (MixPluginB* other) {
    xs::call_next_method(cv, &ST(0), items, G_DISCARD);
    if (other) THIS->val = other->val;
}

void MixPluginB::DESTROY () {
    xs::call_next_method(cv, &ST(0), items, G_DISCARD);
    delete THIS;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::Wrap
PROTOTYPES: DISABLE

Wrapped* Wrapped::new (int arg) {
    RETVAL = new Wrapped(arg);
}

int Wrapped::val (SV* newval = NULL) {
    if (newval) THIS->val = SvIV(newval);
    RETVAL = THIS->val;
}

int Wrapper::xval (SV* newval = NULL) {
    if (newval) THIS->xval = SvIV(newval);
    RETVAL = THIS->xval;
}

void Wrapper::DESTROY ()



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyBaseAV
PROTOTYPES: DISABLE

MyBaseAV* MyBaseAV::new (int arg) {
    if (arg) RETVAL = new MyBase(arg);
    else RETVAL = NULL;
}

int MyBaseAV::val () {
    RETVAL = THIS->val;
}

void MyBaseAV::DESTROY ()



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyBaseHV
PROTOTYPES: DISABLE

MyBaseHV* MyBaseHV::new (int arg) {
    if (arg) RETVAL = new MyBase(arg);
    else RETVAL = NULL;
}

int MyBaseHV::val () {
    RETVAL = THIS->val;
}

void MyBaseHV::DESTROY ()


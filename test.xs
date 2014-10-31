#include <xs/xs.h>
#include <panda/refcnt.h>

using panda::shared_ptr;
using panda::RefCounted;

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

class MyRefCounted : public RefCounted {
    public:
    int val;
    MyRefCounted (int val) : val(val) { }
    virtual ~MyRefCounted () {
        dcnt++;
    }
};

class MyRefCountedChild : public MyRefCounted {
    public:
    int val2;
    MyRefCountedChild (int val, int val2) : val2(val2), MyRefCounted(val) { }
    virtual ~MyRefCountedChild () {
        dcnt++;
    }
};

class MyClass {
    public:
    int val;
    MyClass (int val) : val(val) { }
    virtual ~MyClass () {
        dcnt++;
    }
};

class MyClassChild : public MyClass {
    public:
    int val2;
    MyClassChild (int val, int val2) : val2(val2), MyClass(val) { }
    virtual ~MyClassChild () {
        dcnt++;
    }
};

typedef panda::shared_ptr<MyRefCounted> MyRefCountedSP;
typedef panda::shared_ptr<MyRefCountedChild> MyRefCountedChildSP;
typedef panda::shared_ptr<MyClass> MyClassSP;
typedef panda::shared_ptr<MyClassChild> MyClassChildSP;
typedef MyRefCounted PTRMyRefCounted;
typedef MyRefCountedChild PTRMyRefCountedChild;
typedef MyRefCountedSP PTRMyRefCountedSP;
typedef MyRefCountedChildSP PTRMyRefCountedChildSP;
typedef MyClassSP PTRMyClassSP;
typedef MyClassChildSP PTRMyClassChildSP;
#ifdef CPP11X
typedef std::shared_ptr<MyClass> MyClassSSP;
typedef std::shared_ptr<MyClassChild> MyClassChildSSP;
typedef MyClassSSP PTRMyClassSSP;
typedef MyClassChildSSP PTRMyClassChildSSP;
#endif

typedef MyBase  MyOPTR;
typedef MyChild MyOPTRChild;
typedef MyBase  Wrapped;
typedef MyBase  MyBaseAV;
typedef MyBase  MyBaseHV;

static MyRefCounted* st_myrefcounted;
static MyRefCountedSP st_myrefcounted_sp;
static MyClassSP st_myclass_sp;
#ifdef CPP11X
static MyClassSSP st_myclass_ssp;
#endif

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

void hold_myrefcounted (MyRefCounted* obj) {
    obj->retain();
    st_myrefcounted = obj;
}

MyRefCounted* release_myrefcounted () {
    const char* CLASS = "Panda::XS::Test::MyRefCounted";
    MyRefCountedSP autorel(st_myrefcounted);
    st_myrefcounted->release();
    RETVAL = st_myrefcounted;
}

void hold_ptr_myrefcounted (PTRMyRefCounted* obj) {
    obj->retain();
    st_myrefcounted = obj;
}

PTRMyRefCounted* release_ptr_myrefcounted () {
    const char* CLASS = "Panda::XS::Test::PTRMyRefCounted";
    MyRefCountedSP autorel(st_myrefcounted);
    st_myrefcounted->release();
    RETVAL = st_myrefcounted;
}

void hold_myrefcounted_sp (MyRefCountedSP obj) {
    st_myrefcounted_sp = obj;
}

MyRefCountedSP release_myrefcounted_sp () {
    const char* CLASS = "Panda::XS::Test::MyRefCountedSP";
    RETVAL = st_myrefcounted_sp;
    st_myrefcounted_sp.reset();
}

void hold_ptr_myrefcounted_sp (PTRMyRefCountedSP obj) {
    st_myrefcounted_sp = obj;
}

PTRMyRefCountedSP release_ptr_myrefcounted_sp () {
    const char* CLASS = "Panda::XS::Test::PTRMyRefCountedSP";
    RETVAL = st_myrefcounted_sp;
    st_myrefcounted_sp.reset();
}

void hold_myclass_sp (MyClassSP obj) {
    st_myclass_sp = obj;
}

MyClassSP release_myclass_sp () {
    const char* CLASS = "Panda::XS::Test::MyClassSP";
    RETVAL = st_myclass_sp;
    st_myclass_sp.reset();
}

void hold_ptr_myclass_sp (PTRMyClassSP obj) {
    st_myclass_sp = obj;
}

PTRMyClassSP release_ptr_myclass_sp () {
    const char* CLASS = "Panda::XS::Test::PTRMyClassSP";
    RETVAL = st_myclass_sp;
    st_myclass_sp.reset();
}

#ifdef CPP11X

void hold_myclass_ssp (MyClassSSP obj) {
    st_myclass_ssp = obj;
}

MyClassSSP release_myclass_ssp () {
    const char* CLASS = "Panda::XS::Test::MyClassSSP";
    RETVAL = st_myclass_ssp;
    st_myclass_ssp.reset();
}

void hold_ptr_myclass_ssp (PTRMyClassSSP obj) {
    st_myclass_ssp = obj;
}

PTRMyClassSSP release_ptr_myclass_ssp () {
    const char* CLASS = "Panda::XS::Test::PTRMyClassSSP";
    RETVAL = st_myclass_ssp;
    st_myclass_ssp.reset();
}

#endif

I32 test_typemap_incast_av (SV* arg) {
    AV* arr = typemap_incast<AV*>(arg);
    arr = typemap_incast<AV*>(arg); arr = typemap_incast<AV*>(arg);
    RETVAL = av_len(arr)+1;
}

I32 test_typemap_incast_av2 (SV* arg, SV* arg2) {
    RETVAL = av_len(typemap_incast<AV*>(arg))+av_len(typemap_incast<AV*>(arg2))+2;
}

int test_typemap_incast_myrefcounted (SV* arg) {
    RETVAL = typemap_incast<MyRefCounted*>(arg)->val;
}

SV* test_typemap_outcast_av (SV* listref) {
    AV* list = typemap_incast<AV*>(listref);
    AV* ret = newAV();
    if (list) for (int i = 0; i <= av_len(list); ++i) av_push(ret, newSViv(1));
    RETVAL = typemap_outcast<AV*>(ret);
}

SV* test_typemap_outcast_complex (SV* inobjref) {
    MyRefCountedChildSP inobj = typemap_incast<MyRefCountedChildSP>(inobjref);
    AV* ret = newAV();
    av_push(ret, newSViv(inobj->val));
    av_push(ret, typemap_outcast<MyClassSP, const char* CLASS>(MyClassSP(new MyClass(inobj->val2)), "Panda::XS::Test::MyClassSP"));
    RETVAL = typemap_outcast<AV*>(ret);
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
    HV* CLASS = SvSTASH(THIS);
    RETVAL = THIS;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::OPTR
PROTOTYPES: DISABLE

MyOPTR* MyOPTR::new (int arg) {
    if (arg) RETVAL = new MyOPTR(arg);
    else RETVAL = NULL;
    //printf("CREATED ADDR=%llu\n", RETVAL);
}

int MyOPTR::val (SV* newval = NULL) {
    //printf("GOT ADDR=%llu\n", THIS);
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



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyRefCounted
PROTOTYPES: DISABLE

MyRefCounted* MyRefCounted::new (int val) {
    RETVAL = new MyRefCounted(val);
}

int MyRefCounted::val () {
    RETVAL = THIS->val;
}

void MyRefCounted::DESTROY ()



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyRefCountedChild
PROTOTYPES: DISABLE

MyRefCountedChild* MyRefCountedChild::new (int val, int val2) {
    RETVAL = new MyRefCountedChild(val, val2);
}

int MyRefCountedChild::val2 () {
    RETVAL = THIS->val2;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyRefCountedSP
PROTOTYPES: DISABLE

MyRefCountedSP new (SV* CLASS, int val) {
    RETVAL = new MyRefCounted(val);
}

int val (MyRefCountedSP THIS) {
    RETVAL = THIS->val;
}

void DESTROY (MyRefCountedSP THIS)



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyRefCountedChildSP
PROTOTYPES: DISABLE

MyRefCountedChildSP new (SV* CLASS, int val, int val2) {
    RETVAL = new MyRefCountedChild(val, val2);
}

int val2 (MyRefCountedChildSP THIS) {
    RETVAL = THIS->val2;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyClassSP
PROTOTYPES: DISABLE

MyClassSP new (SV* CLASS, int val) {
    RETVAL = MyClassSP(new MyClass(val));
}

int val (MyClassSP THIS) {
    RETVAL = THIS->val;
}

void DESTROY (MyClassSP THIS)



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyClassChildSP
PROTOTYPES: DISABLE

MyClassChildSP new (SV* CLASS, int val, int val2) {
    RETVAL = MyClassChildSP(new MyClassChild(val, val2));
}

int val2 (MyClassChildSP THIS) {
    RETVAL = THIS->val2;
}



#ifdef CPP11X

MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyClassSSP
PROTOTYPES: DISABLE

MyClassSSP new (SV* CLASS, int val) {
    RETVAL = MyClassSSP(new MyClass(val));
}

int val (MyClassSSP THIS) {
    RETVAL = THIS->val;
}

void DESTROY (MyClassSSP THIS)



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::MyClassChildSSP
PROTOTYPES: DISABLE

MyClassChildSSP new (SV* CLASS, int val, int val2) {
    RETVAL = MyClassChildSSP(new MyClassChild(val, val2));
}

int val2 (MyClassChildSSP THIS) {
    RETVAL = THIS->val2;
}


#endif



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::PTRMyRefCounted
PROTOTYPES: DISABLE

PTRMyRefCounted* PTRMyRefCounted::new (int val) {
    RETVAL = new MyRefCounted(val);
}

int PTRMyRefCounted::val () {
    RETVAL = THIS->val;
}

void PTRMyRefCounted::DESTROY ()



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::PTRMyRefCountedChild
PROTOTYPES: DISABLE

PTRMyRefCountedChild* PTRMyRefCountedChild::new (int val, int val2) {
    RETVAL = new MyRefCountedChild(val, val2);
}

int PTRMyRefCountedChild::val2 () {
    RETVAL = THIS->val2;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::PTRMyRefCountedSP
PROTOTYPES: DISABLE

PTRMyRefCountedSP new (SV* CLASS, int val) {
    RETVAL = new MyRefCounted(val);
}

int val (PTRMyRefCountedSP THIS) {
    RETVAL = THIS->val;
}

void DESTROY (PTRMyRefCountedSP THIS)



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::PTRMyRefCountedChildSP
PROTOTYPES: DISABLE

PTRMyRefCountedChildSP new (SV* CLASS, int val, int val2) {
    RETVAL = new MyRefCountedChild(val, val2);
}

int val2 (PTRMyRefCountedChildSP THIS) {
    RETVAL = THIS->val2;
}



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::PTRMyClassSP
PROTOTYPES: DISABLE

PTRMyClassSP new (SV* CLASS, int val) {
    RETVAL = MyClassSP(new MyClass(val));
}

int val (PTRMyClassSP THIS) {
    RETVAL = THIS->val;
}

void DESTROY (PTRMyClassSP THIS)



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::PTRMyClassChildSP
PROTOTYPES: DISABLE

PTRMyClassChildSP new (SV* CLASS, int val, int val2) {
    RETVAL = MyClassChildSP(new MyClassChild(val, val2));
}

int val2 (PTRMyClassChildSP THIS) {
    RETVAL = THIS->val2;
}



#ifdef CPP11X

MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::PTRMyClassSSP
PROTOTYPES: DISABLE

PTRMyClassSSP new (SV* CLASS, int val) {
    RETVAL = MyClassSSP(new MyClass(val));
}

int val (PTRMyClassSSP THIS) {
    RETVAL = THIS->val;
}

void DESTROY (PTRMyClassSSP THIS)



MODULE = Panda::XS::Test                PACKAGE = Panda::XS::Test::PTRMyClassChildSSP
PROTOTYPES: DISABLE

PTRMyClassChildSSP new (SV* CLASS, int val, int val2) {
    RETVAL = MyClassChildSSP(new MyClassChild(val, val2));
}

int val2 (PTRMyClassChildSSP THIS) {
    RETVAL = THIS->val2;
}


#endif
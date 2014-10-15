package Panda::XS;
use 5.012;

=head1 NAME

Panda::XS - useful features and typemaps for XS modules.

=cut

our $VERSION = '0.1.4';
require Panda::XSLoader;
Panda::XSLoader::load();

=head1 DESCRIPTION

Panda::XS provides some useful features for XS modules. Also adds default configurable typemaps with most commonly used types.
Panda::XS makes it possible for other modules (Perl or XS) to inherit from your XS module.
To use it you must have a C++ compiler.
Of course most (or all) CPAN modules have private implementation visible only via perl interface (function or method calls).
But it is a much better approach to implement functionality in C/C++ classes with public API, make an XS interface, to make it
usable from perl and also make you C code visible to other XS modules. This makes it possible for other users to use your
C code directly from other XS modules, without perl method/function interface and therefore they can achieve much greater speeds.
To make your C code visible to other XS modules when your module is installed, see L<Panda::Install>.

=head1 SYNOPSIS

Makefile.PL:

    use strict;
    use Panda::Install 'write_makefile';
    
    write_makefile(
        NAME    => 'MyXS',
        CPLUS   => 1,
        DEPENDS => 'Panda::XS',
    );
    
mytypemap.map:

    MyClass*  T_OPTR
    MyClass3* T_OEXT

MyXS.xs:

    #include <xs/xs.h> /* replaces #include perl.h, ppport.h, XSUB.h, etc... */
    
    ...
    
    # C++ class based object
    MyClass*
    MyClass::new ()
    CODE:
        RETVAL = new MyClass();
        ... // scalar-reference based object. IV value is C pointer address.
    
    void
    MyClass::somefunc ()
    PPCODE:
        THIS->somefunc();
        ...
    
    void
    MyClass::DESTROY ()
    
    # hash and C++ class based object at one time
    using xs::sv_payload_attach;
    using xs::rv_payload;
    MODULE=... PACKAGE=MyClass2
    
    SV*
    new (const char* CLASS)
    CODE:
        RETVAL = sv_bless( newRV_noinc((SV*)newHV()), gv_stashpv(CLASS, GV_ADD) );
        rv_payload_attach(RETVAL, new MyClass2());
    OUTPUT:
        RETVAL
        
    void
    somefunc (SV* OBJ)
    PPCODE:
        if (!SvROK(OBJ)) croak("....");
        MyClass2* THIS = (MyClass2*) rv_payload(OBJ);
        assert(THIS);
        ...
        
    void
    DESTROY (SV* OBJ)
    PPCODE:
        if (!SvROK(OBJ)) croak("....");
        MyClass2* THIS = (MyClass2*) rv_payload(OBJ);
        delete THIS;
        
        
    # ANY-SV and C++ class based object at one time
    MyClass3*
    MyClass3::new ()
    CODE:
        RETVAL = new MyClass2();

    void
    MyClass3::somefunc ()
    PPCODE:
        THIS->somefunc();
        ...

    void
    MyClass3::DESTROY ()
    
MyXS.pm:

    package MyXS;
    use Panda::XS;
    
    our $VERSION = '0.1.3';
    require Panda::XSLoader;
    Panda::XSLoader::bootstrap(); # replacement for XSLoader::load()



=head1 TYPEMAP

=over C types

=item (u)int(8/16/32/64)_t

Mappings for integers

=item AV*, HV*, CV*, IO*

Array/Hash/Code/IO references.

    AV*
    get_list ()
    CODE:
        RETVAL = newAV();
        // push values to RETVAL
        
    
    void
    merge (HV* h1, HV* h2)
    PPCODE:
        ...
        
=item OSV*, OAV*, OHV*, OIO*

Scalar/Array/Hash/IO reference based objects.

    OHV*
    OHV::new ()
    CODE:
        RETVAL = newHV();


    int
    OAV::get_count ()
    CODE:
        RETVAL = *av_fetch(THIS, 1, 1);

=back

=over Typemap classes (to map your custom types/classes to)

=item T_OPTR

=item YOUR_TYPE : T_OPTR([basetype=classname], [nocast=1])

IV(SCALAR)-based object with C pointer attached.

    TYPEMAP
    MyClass* T_OPTR
    
    # XS
    
    MyClass*
    MyClass::new ()
    CODE:
        RETVAL = new MyClass();
        
    void
    MyClass::somefunc()
    PPCODE:
        // use 'THIS' (MyClass*)
        
    void
    MyClass::DESTROY ()

The main problem of this method is that one cannot fully inherit from your module (no place to store another class' data).
However you can still use inheritance XS->XS->... if your child's XS uses C++ class which inherits from parent's C++ class.
In this case, set 'basetype' to the name of the most parent C++ class. See C<HOW TO> for details.

=item T_OEXT

=item YOUR_TYPE : T_OEXT([basetype=classname], [nocast=1])

Extendable object with C pointer attached.

    TYPEMAP
    MyClass* T_OEXT
    
    # XS
    
    MyClass*
    MyClass::new ()
    CODE:
        RETVAL = new MyClass();
        
    
    void
    MyClass::somefunc()
    PPCODE:
        // use 'THIS' (MyClass*)

    void
    MyClass::DESTROY ()
    
This method is much more flexible as it allows for inheritance and even XS -> XS inheritance where each one holds its own C++ object.

<T_OEXT C type>::new will create scalar-based object (reference to undef)

    my $obj = MyClass->new; # $obj is RV to undef with C++ MyClass attached
    
Use obj2hv / obj2av to change the object's base to desired type.

    Panda::XS::obj2hv($obj); # $obj is RV to HV with C++ MyClass attached

or

    Panda::XS::obj2av($obj); # $obj is RV to AV with C++ MyClass attached

After that you can store data in $obj->{..} or $obj->[..] as if it was a regular perl object

=over Parameters

=item basetype [default is $type]

The most parent C++ class in XS hierarchy. Used as a marker(key) for storing C++ pointer in perl object's magic. Also used for
auto typecasting from parent class to child class like this 'THIS = dynamic_cast<$type>(($basetype)stored_ptr)' for input typemaps
and from child class to parent class in output typemaps 'stored_ptr = static_cast<$basetype>(RETVAL)'.
By default $basetype = $type. If $basetype == $type, then casting is not performed. See C<HOW TO> for details.

=item nocast [default is 0]

If set, disables typecasting described in 'basetype' section even if $basetype != $type. Useful for storing objects in wrappers.
See C<HOW TO> for details.

=back

=over Special C variables for OUTPUT

=item CLASS (required)

Define this variable as either 'const char*' or 'SV*' or 'HV*' and set it to a class name or a class stash (HV*) you want your
object to be blessed to. It is done automatically for methods 'new', so that you must not define this variable in 'new' methods.
However you can change it's value if you want to.

=over To receive maximum perfomance, follow these rules (in order they appear):

=item If you already have class stash, set HV* CLASS.

For example, in an object method, which returns another object, like 'clone':

    HV* CLASS = SvSTASH(SvRV(ST(0)))
    
It's the most effective way for Panda::XS to bless your newly created object. However doing this:

    HV* CLASS = gv_stashpv(classname_str, GV_ADD);
    
won't lead to any perfomance gain over setting const char* CLASS.

=item If not, but you have a class name in SV*, set SV* CLASS:

For example, in a class method, which creates object.

    SV* CLASS = ST(0);
    
In some cases it runs much faster than setting const char* CLASS (when ST(0) is a shared COW string, since perl 5.21.4).

Don't do it for method 'new' because ExtUtils::ParseXS automatically sets "const char* CLASS = SvPV_nolen(ST(0));" which
unfortunately is not the most effective way. Of course it happens only if you "typemap"ed your function (MyClass* MyClass::new ())

=item If you don't have anything of above, set const char* CLASS

For example, in constructors that are called as functions, not as class methods, like 'uri("http://ya.ru")'

    const char* CLASS = "MyFramework::URI";

=back

=item self

This variable is automatically defined for all T_OEXT outputs and is set to NULL. If you don't change its value, then a new object
(reference to undef) will be created and your RETVAL will be attached to it. If you want to attach your RETVAL to an already
existing object, set 'self' variable to some SV* value. Value must be a valid RV to a blessed SV, or an SV itself
(in this case an RV to specified SV is created and blessed). Useful for calling super and next methods.
See C<HOW TO> for details.

=back

=item T_OEXT_AV, T_OEXT_HV

HV or AV based object with C pointer attached.

    TYPEMAP
    MyClass* T_OEXT_HV
    
    # XS
    
    MyClass*
    MyClass::new ()
    CODE:
        RETVAL = new MyClass();

    void
    MyClass::somefunc()
    PPCODE:
        // use THIS (MyClass*)

    void
    MyClass::DESTROY ()
    
    # in perl code
    my $obj = MyClass->new; # $obj is a blessed HASHREF
    $obj->somefunc;
    
the above works like

    TYPEMAP
    MyClass* T_OEXT
    
    # XS
    
    MyClass*
    MyClass::new ()
    CODE:
        RETVAL = new MyClass();
        
    void
    MyClass::DESTROY ()

    # in perl code
    my $obj = MyClass->new; # $obj is a blessed SCALARREF (ref to undef)
    Panda::XS::obj2hv($obj); # $obj is a blessed HASHREF

and exactly like

    TYPEMAP
    MyClass* MY_TYPE
    
    OUTPUT
    MY_TYPE : T_OEXT
         if (!self && $var) self = (SV*)newHV();
         
    INPUT
    MY_TYPE : T_OEXT
    
    # XS
    
    MyClass*
    MyClass::new ()
    CODE:
        RETVAL = new MyClass();

    # in perl code
    my $obj = MyClass->new; # $obj is a blessed HASHREF

=back



=head1 HOW TO

=head2 CREATE AN XS CLASS HOLDING C++ CLASS OR C STRUCTURE

Here and below by 'XS CLASS' i mean not just XS code with functions, i mean class, objects of which hold a C struct or class.

=over

=item Create your TYPE in typemap using one of existing typemap classes.

Either classic pointer-based object

    MyClass* T_OPTR
    
or more flexible "attached pointer" object

    MyClass* T_OEXT
    
=item Use your type in XS code

    MyClass*
    MyClass::new ()
    CODE:
        RETVAL = new MyClass();
    OUTPUT:
        RETVAL

    void
    MyClass::somefunc ()
    PPCODE:
        THIS->somefunc(); // THIS is a variable of type MyClass*
        ...

    void
    MyClass::DESTROY ()

=item Use your XS class from perl

    my $obj = new MyClass();
    $obj->somefunc();
    
Note how your object looks like inside with T_OPTR

    DB<2> x $obj
      0  MyClass=SCALAR(0x8179dc4e0)
         -> 34732484608

or with T_OEXT

    DB<5> x $obj
      0  MyClass=SCALAR(0x8179e16a8)
         -> undef

=back


=head2 CREATE AN EXTENDABLE XS CLASS HOLDING C++ CLASS OR C STRUCTURE

'Extendable' means that we can create child class in perl and hold additional data in $self as it was a regular perl object.
It's impossible to implement that using T_OPTR as it makes perl object not applicable for holding anything but C pointer.
To do this, we must use T_OEXT typemap class. By default, T_OEXT creates reference to undef as an object base. Most of the time
we want it to be a hash reference. There are 2 ways we can achieve that - either use T_OEXT_HV as typemap class
(it creates RV to HV as an object base instead of RV to undef) or upgrade already created object to RV/HV from perl.

=over

=item Solution with T_OEXT_HV

In typemap change T_OEXT to T_OEXT_HV:

    MyClass* T_OEXT_HV
    
That's all! Lets see the results

    DB<6> x new MyClass()
      0  MyClass=HASH(0x81794bf48)
           empty hash
    
=item Solution with object upgrading

Lets do the upgrade in child class.

    package MyClassChild;
    use parent 'MyClass';
    
    sub new {
        my $self = shift->SUPER::new(@_);
        Panda::XS::obj2hv($self);
        return $self;
    }
    
Lets see the results

    DB<5> x new MyClass()
      0  MyClass=SCALAR(0x81794bd80)
         -> undef
    DB<6> x new MyClassChild()
      0  MyClassChild=HASH(0x81794a318)
           empty hash

=back


=head2 CREATE XS CLASS HIERARCHY THAT CORRESPONDS TO C++ CLASS HIERARCHY

Image that you need to port a C framework to perl and you want to leave it's classes structure transparent.
For example, there is a C framework Foo that we need to port to perl. It has 2 classes ClassA and ClassB.

    class ClassA {
    private:
        int _propA;
    public:
        ClassA (int propA = 0) : _propA(propA) {}
        
        int  propA ()        { return _propA; }
        void propA (int val) { _propA = val; }
        
        virtual ClassA* clone () { return new ClassA(_propA); }
    }

    class ClassB : public ClassA {
    private:
        int _propB;
    public:
        ClassB (int propA = 0, int propB = 0) : ClassA(propA), _propB(propB) {}

        int  propB ()        { return _propB; }
        void propB (int val) { _propB = val; }

        ClassB* clone () { return new ClassB(_propA, _propB); }
    }

We want to create 2 perl classes - Foo::A which holds C ClassA class and Foo::B which holds C ClassB class. Of course
Foo::B should inherit from Foo::A. What do we have to do? Almost nothing!

At first, create a custom typemap class for ClassA/ClassB hierarchy, inherit it from T_OEXT and set parameter basetype
to the most parent class which will be visible in perl. In our case it is ClassA (visible via Foo::A).

    ClassA* T_FOO
    ClassB* T_FOO
    
    OUTPUT
    T_FOO : T_OEXT(basetype=ClassA*)
    INPUT
    T_FOO : T_OEXT(basetype=ClassA*)
    
Remember that basetype is required in case of C++ inheritance, otherwise you won't be able to call Foo::A methods on a Foo::B object.

Then lets create an XS code.

Foo.xs (Here and after we use extended L<Panda::Install> XS syntax to make XS functions look like C functions)

    MODULE = Foo                PACKAGE = Foo::A
    PROTOTYPES: DISABLE

    ClassA* ClassA::new (int propA) {
        RETVAL = new ClassA(propA);
    }

    int ClassA::propA (SV* newval = NULL) { // 'THIS' is a ClassA* pointer, even if real perl object is of Foo::B class.
        if (newval) THIS->propA(SvIV(newval));
        RETVAL = THIS->propA();
    }
    
    ClassA* ClassA::clone () {
        HV* CLASS = SvSTASH(SvRV(ST(0)));
        RETVAL = THIS->clone();
    }
    
    void ClassA::DESTROY ()

    MODULE = Foo                PACKAGE = Foo::B
    PROTOTYPES: DISABLE

    ClassB* ClassB::new (int propA, int propB) {
        RETVAL = new ClassB(propA, propB);
    }

    int ClassB::propB (SV* newval = NULL) { // 'THIS' is a ClassB* pointer
        if (newval) THIS->propB(SvIV(newval));
        RETVAL = THIS->propB();
    }
    
Somewhere in Perl

    my $a = new Foo::A(123);
    say $a->propA;
    $a->propA(321);
    say ref $a->clone; # Foo::A
    
    my $b = new Foo::B(1,2);
    say $b->propA;
    say $b->propB;
    say ref $b->clone; # Foo::B
    
Using these technics you can port any C++ framework saving its original OOP structure, keeping your XS wrapper as thin as possible
and therefore get maximum perfomance.

=head2 PASSING C CLASSES/STRUCTURES AS A PARAMETERS TO FUNCTIONS OF OTHER CLASSES.

It works out of the box. Lets add a third class to previous example, ClassC:

    class ClassC {
    public:
        ClassC () {}
        
        int calculate (ClassA* arg) { return arg->propA * arg->propA; }
    }
    
Add it to a typemap

    ClassC* T_OEXT
    
Add XS for ClassC

    MODULE = Foo                PACKAGE = Foo::C
    PROTOTYPES: DISABLE

    ClassC* ClassC::new ()

    int ClassC::calculate (ClassA* arg)
    
    void ClassC::DESTROY ()

Just do it in perl as you would in C++, typemaps will do all the work for you

    my $a = new Foo::A(10);
    my $b = new Foo::B(20, 30);
    my $c = new Foo::C;
    say $c->calculate($a); # 100;
    say $c->calculate($b); # 400;
    
Remember, everywhere you pass/receive Foo::A, Foo::B etc, in XS you receive/return ClassA*, ClassB*, etc

=head2 INHERITING XS CLASS FROM ANOTHER WITH DIFFERENT UNDERLYING DATA.

Sometimes source code of parent class is unavailable, and therefore you can't make a C++ child class as described above. However you
can still provide such inheritance on perl level. All you need to do is to call SUPER in constructor.

Suppose we have two C++ classes Bow and Milk. And we already have an XS class for Bow. We want to implement XS for Milk and inherit
it from Bow. As want 2 different C data pointers in one perl object, we should either not provide a basetype parameter in typemap,
or set it to something different from Bow*. By default (if not provided), basetype is set to the value of final type name.
However we need to call SUPER::new, and attach our data to existing SV, rather than creating new one (otherwise Bow's data would be lost).
To do this, set 'self' variable to SV object to attach to.
Unfortunately, as of current perl (5.21.5), it's impossible to call SUPER/next from XS. To call SUPER/next, use the API provided by
L<Panda::XS> C++ interface - call_super.

Typemap:

    Bow*  T_OEXT
    Milk* T_OEXT
    
Milk.pm:
    
    package Foo::Milk;
    use parent 'Some::Bow';

XS:

    MODULE = Foo                PACKAGE = Foo::Milk
    PROTOTYPES: DISABLE

    Milk* Milk::new (...) {
        self = xs::call_super(cv, &ST(0), items);
        RETVAL = new Milk();
    }

    void Milk::something () {
        // 'THIS' is a Milk* pointer
    }
    
    Milk* Milk::clone () { // cloning just Milk* without Bow* does NOT make sense. So we must call SUPER::clone
        HV* CLASS = SvSTASH(SvRV(ST(0)));
        self = xs::call_super(cv, &ST(0), items);
        RETVAL = THIS->clone();
    } // new Foo::Milk object returned containing cloned Milk* and Bow* classes.
    
    void Milk::DESTROY () {
        xs::call_super(cv, &ST(0), items, G_DISCARD);
        delete THIS;
    }
    
=head2 CREATE AN XS CLASS WHICH IS SUITABLE FOR MULTIPLE IHERITANCE / C3 CLASS MIXIN

All you need to do is to call next::method or maybe::next::method from your construtor.
To do this, use call_next_method() or call_next_maybe() from xs:: namespace.

Typemap:

    MyPlugin*  T_OEXT
    
Perl:
    
    package Foo::MyPlugin;
    use mro 'c3';    
    
XS:

    MODULE = Foo                PACKAGE = Foo::MyPlugin
    PROTOTYPES: DISABLE

    MyPlugin* MyPlugin::new (...) {
        self = xs::call_next_maybe(cv, &ST(0), items);
        RETVAL = new MyPlugin();
    }

    uint32_t MyPlugin::something () {
        // 'THIS' is a MyPlugin* pointer
        RETVAL = THIS->something;
    }
    
    MyPlugin* MyPlugin::clone () {
        HV* CLASS = SvSTASH(SvRV(ST(0)));
        self = xs::call_next_maybe(cv, &ST(0), items);
        RETVAL = THIS->clone();
    } // new Foo::MyPlugin object returned containing cloned MyPlugin* and all data of other classes
    
    void MyPlugin::DESTROY () {
        xs::call_next_maybe(cv, &ST(0), items, G_DISCARD);
        delete THIS;
    }
    
Perl:

    package MyServer;
    use parent qw/Foo::MyPlugin Foo::Milk/;
    
    my $obj = new MyServer();
    
=head2 CREATE AN XS CLASS HOLDING C++ CLASS AND ADDITIONAL C INFO

Sometimes you need to hold additional info in XS class, but you can't or don't want to create additional fields in your C++ class.
Let's see an example. Assume we have a 'Driver' C++ class that we want to port. We'll make Foo::Driver perl class.

    #TYPEMAP
    Driver* T_OEXT
    
    #XS
    
    Driver* Driver::new (int arg1, char* arg2) {
        RETVAL = new Driver(arg1, arg2);
    }
    
    int Driver::category () {
        RETVAL = THIS->category;
    }
    
    char* Driver::name () {
        RETVAL = THIS->name;
    }

    void Driver::ban (int why) {
        THIS->ban(why);
    }
    
    HV* Driver::get_history () {
        DriverHistory* history = THIS->get_history();
        RETVAL = newHV();
        // fill RETVAL with data from DriverHistory*
    }

    void
    Driver::DESTROY ()
    
Now imagine that we want to count, how many times a driver has been banned for particular object. But Driver class doesn't
have any field to hold this value. Adding it to Driver, even if you can, would be a bad decision as it shouldn't know anything
about your XS class behaviour. Also filling up HV every time 'get_history' is called, could be quite expensive, so that we also
would like to cache once built result somewhere. How to do that?

=over

=item Solution 1: create Driver's child class.
    
    class DriverXS : public Driver {
        public:
        
        int counter;
        HV* cached_history;
        
        DriverXS (int arg1, char* arg2) : counter(0), cached_history(NULL), Driver(arg1, arg2) {}
        
        ~DriverXS () {
            SvREFCNT_dec(cached_history);
        }
    }

Now use your child class instead of Driver

    #TYPEMAP
    DriverXS* T_OEXT
    
    #XS
    
    DriverXS* DriverXS::new (int arg1, char* arg2) {
        RETVAL = new DriverXS(arg1, arg2);
    }
    
    int DriverXS::category () {
        RETVAL = THIS->category;
    }
    
    char* DriverXS::name () {
        RETVAL = THIS->name;
    }

    void DriverXS::ban (int why) {
        THIS->counter++;
        THIS->ban(why);
    }
    
    HV* DriverXS::get_history () {
        if (!THIS->cached_history) {
            DriverHistory* history = THIS->get_history();
            THIS->cached_history = newHV();
            // fill cached_history with data from DriverHistory*
        }
        RETVAL = THIS->cached_history;
    }

    void
    DriverXS::DESTROY ()
    
Although this will work out for our case, this approach may be unacceptable. For example imagine we have DriverStorage in C++ lib
and class method get_driver_by_id. How can we port it? Lets create XS class Foo::DriverStorage. And method get_driver_by_id:

    DriverXS* DriverStorage::get_driver_by_id (int id) {
        RETVAL = THIS->get_driver_by_id(id);
    }
    
But wait a minute, our c++ lib's get_driver_by_id returns Driver* of course, as it doesn't know anything about DriverXS.
And even if we stored only DriverXS* objects in DriverStorage, some C++ code might have created a simple Driver* object and store
it in DriverStorage. So the example above won't even compile. The only way is to create a copy DriverXS* from Driver*.

    DriverXS* DriverStorage::get_driver_by_id (int id) {
        Driver* driver = THIS->get_driver_by_id(id);
        if (!driver) XSRETURN_UNDEF;
        RETVAL = new DriverXS(driver->category, driver->name); // or new DriverXS(driver) if have such constructor
    }
    
But it might be expensive and not every object can be copied (for example, socket handle classes).

=item Solution 2: create a wrapper, and wrap Driver objects into it.

    class DriverXS {
        public:
        
        Driver* obj;
        int counter;
        HV* cached_history;
        
        DriverXS (Driver* driver) : counter(0), cached_history(NULL), obj(driver) {}
        
        ~DriverXS () {
            SvREFCNT_dec(cached_history);
            delete obj;
        }
    }
    
    #TYPEMAP
    DriverXS* T_OEXT
    
    #XS
    DriverXS* DriverXS::new (int arg1, char* arg2) {
        RETVAL = new DriverXS(new Driver(arg1, arg2));
    }
    
    int DriverXS::category () {
        RETVAL = THIS->obj->category;
    }
    
    char* DriverXS::name () {
        RETVAL = THIS->obj->name;
    }

    void DriverXS::ban (int why) {
        THIS->counter++;
        THIS->obj->ban(why);
    }
    
    HV* DriverXS::get_history () {
        if (!THIS->cached_history) {
            DriverHistory* history = THIS->obj->get_history();
            THIS->cached_history = newHV();
            // fill cached_history with data from DriverHistory*
        }
        RETVAL = THIS->cached_history;
    }

    void
    DriverXS::DESTROY ()

    ...
    DriverXS* DriverStorage::get_driver_by_id (int id) {
        Driver* driver = THIS->get_driver_by_id(id);
        if (!driver) XSRETURN_UNDEF;
        RETVAL = new DriverXS(driver);
    }
    
This approach is much more flexible as it allows you to return perl objects even for c++ objects who wasn't created in XS class.
But our code is not good enough for now, because it's very annoying to write THIS->obj. Moreover, if you share your module with
someone, they will have to know about your wrapper to work with your XS objects. For example, image you've uploaded Foo to CPAN.
Someone is using it:

    write_makefile(
        ...
        DEPENDS => ['Foo'], # make C headers, and typemaps of Foo visible to my XS/C code
    );
    
    # some user's XS
    
    void
    change_drivers_name (DriverXS* driverxs, const char* newname)
    PPCODE:
        Driver* driver = driverxs->obj;
        driver->set_name(newname);
        
        
    # perl code
    my $driver = Foo::Driver->new(1, "vasya");
    Bar::change_drivers_name($driver, "petya");
    say $driver->name;
    
No one should know the details of your XS module (about the fact that you wrap real Driver into DriverXS).
To do that, we need to implement all the details in typemap, not in XS functions itself.
We will need to create our own typemap class.

    #TYPEMAP
    DriverXS* XT_FOO_DRIVERXS
    Driver*   XT_FOO_DRIVER
    
    OUTPUT
    XT_FOO_DRIVERXS : T_OEXT(basetype=DriverXS*)
    
    XT_FOO_DRIVER : XT_FOO_DRIVERXS(nocast=1)
        $var = ($type)new DriverXS($var);
        
    INPUT
    XT_FOO_DRIVERXS : T_OEXT(basetype=DriverXS*)
    
    XT_FOO_DRIVER : XT_FOO_DRIVERXS(nocast=1)
        $var = dynamic_cast<$type>(((DriverXS*)$var)->obj);
        
Note that dynamic_cast is not needed in this case, but it would be needed in more complex cases, for example if you had several
Driver::A, Driver::B, Driver::C classes extending basic Driver, and you made corresponding XS classes Foo::Driver::A, etc,
you would need this typecast to properly handle pointers.

Ok now our code looks much better:

    Driver* Driver::new (int arg1, char* arg2) {
        RETVAL = new Driver(arg1, arg2);
    }
    
    int Driver::category () {
        RETVAL = THIS->category;
    }
    
    char* Driver::name () {
        RETVAL = THIS->name;
    }

    void DriverXS::ban (int why) {
        THIS->counter++;
        THIS->obj->ban(why);
    }
    
    HV* DriverXS::get_history () {
        if (!THIS->cached_history) {
            DriverHistory* history = THIS->obj->get_history();
            THIS->cached_history = newHV();
            // fill cached_history with data from DriverHistory*
        }
        RETVAL = THIS->cached_history;
    }

    void
    DriverXS::DESTROY ()

    ...
    Driver* DriverStorage::get_driver_by_id (int id) {
        RETVAL = THIS->get_driver_by_id(id);
    }
    
Note how we use Driver:: and DriverXS:: typemaps. DriverXS is a private typemap and only needed in Driver XS class module itself,
and only in functions which need those additional fields (counter and cached_history). Most of the time, Driver:: is in use.
Now the implementation details are hidden from users of your module. And the third-party example above will now look much clearer:

    void
    change_drivers_name (Driver* driver, const char* newname)
    PPCODE:
        driver->set_name(newname);

Users of your module no longer see DriverXS wrapper.

Important! In such cases destructor (DESTROY) MUST always be defined for DriverXS:: typemap. If you define it for Driver:: typemap

    void
    Driver::DESTROY ()

only Driver* object will be destroyed, leaving DriverXS* object inaccessible.

=back

=head2 REFERENCE COUNTING PROBLEM

While you only have single XS classes without any relationships with each other, everything's ok. Problems begin in the following
example (we use simple (without wrapper) Driver* class and XS from previous examples):

    class Insurance {
        private:
        Driver* _first_driver;
        Driver* _second_driver;
        
        public:
        Insurance () {
            _first_driver = new Driver(1, "john");
            _second_driver = new Driver(2, "mike");
        }
        
        Driver* first_driver  ()            { return _first_driver; }
        Driver* second_driver ()            { return _second_driver; }
        void    first_driver  (Driver* val) { _first_driver = val; }
        void    second_driver (Driver* val) { _second_driver = val; }
        
        ~Insurance () {
            delete _first_driver;
            delete _second_driver;
        }
    }
    
    #XS
    
    Insurance* Insurance::new () {
        RETVAL = new Insurance();
    }
    
    Driver* Insurance::first_driver (Driver* newval = NULL) : ALIAS(second_driver=1) {
        if (newval) {
            if (ix == 0) THIS->first_driver(newval);
            else         THIS->second_driver(newval);
            XSRETURN_UNDEF;
        }
        if (ix == 0) RETVAL = THIS->first_driver();
        else         RETVAL = THIS->second_driver();
    }
    
    void Insurance::DESTROY ()
    
So where is the problem? Right here:

    #perl code
    my $insurance = new Foo::Insurance;
    say $insurance->first_driver->name; # prints "john"
    say $insurance->first_driver->name; # OOPS. core dump or undefined behaviour
    
When first_driver() is called for the first time, it creates perl object and attaches Driver* object to it. After first say(),
the temporary perl variable holding Driver perl object no longer needed and destroyed. Destructor (DESTROY) of Driver's XS class
destroys Driver* object as well. Pointer to that freed object still remains in Insurance* object and bad things happen.
Ok, lets stop deleting Driver* object from Driver::DESTROY(), i.e. remove this function:

    void
    Driver::DESTROY ()
    
In this case we get a memory leak for this type of code:

    for (1..1000) {
        my $driver = new Foo::Driver(1, "myname");
    }
    
How can we avoid deletion in first case and memory leak in second? With current design - we can't.
To fix that we need to add a reference counter to our objects.

    class Driver {
        private:
        mutable int _refcnt;
        ....
        Driver (...) : _refcnt(0) ... { ... }
        void retain () const { _refcnt++; }
        void release  () const { if (--_refcnt <= 0) delete this; }
        virtual ~Driver () {...}
    }
    
    class Insurance {
        ...
        void first_driver  (Driver* val) {
            if (_first_driver) _first_driver->release();
            _first_driver = val;
            if (_first_driver) _first_driver->retain();
        }
    }
    
    #XS
    
    Driver* Driver::new (...) {
        RETVAL = new Driver(...);
        RETVAL->retain();
        ...
    }
    
    void Driver::DESTROY () {
        THIS->release();
    }
    
    Driver* Insurance::first_driver (Driver* newval = NULL) : ALIAS(second_driver=1) {
        ...
        if (ix == 0) RETVAL = THIS->first_driver();
        else         RETVAL = THIS->second_driver();
        if (RETVAL) RETVAL->retain();
    }    

We can implement it in typemap to hide these details from XS code.

    #TYPEMAP
    Driver* XT_FOO_DRIVER
    
    OUTPUT
    
    XT_FOO_DRIVER : T_OEXT
        $var->retain();
        
    INPUT
    
    XT_FOO_DRIVER : T_OEXT
    
    #XS
    
    Driver* Driver::new (...) {
        RETVAL = new Driver(...);
        ...
    }
    
    void Driver::DESTROY () {
        THIS->release();
    }
    
    Driver* Insurance::first_driver (Driver* newval = NULL) : ALIAS(second_driver=1) {
        ...
        if (ix == 0) RETVAL = THIS->first_driver();
        else         RETVAL = THIS->second_driver();
    }    

Note, however, that you still need to ->release() object on Driver::DESTROY() as typemap can't do it. Also you need to ->retain()
and ->release() objects in C++ classes code itself properly as in any other refcounted system.

See also L<Panda::Lib>, it has T_OEXT_REFCNT typemap class which does ->retain() for output and a base C++ class 'Refcounted'.



=head1 C FUNCTIONS

All functions and types are in 'xs' namespace so that you will actually need C++ to use them.


=head2 PAYLOAD FUNCTIONS

=head4 void sv_payload_attach (SV* sv, void* ptr, const payload_marker_t* marker = NULL)

Attach payload ptr to sv. Markers allow you to store multiple payloads in a single SV.
Marker doesn't need to be initialized somehow, its just a valid memory pointer. Usually its a static global variable.
If no marker provided, default one is used (global to the whole program).

=head4 bool sv_payload_exists (const SV* sv, const payload_marker_t* marker = NULL)

Returns true if sv has any payload for marker.

=head4 void* sv_payload (const SV* sv, const payload_marker_t* marker = NULL)

Returns payload attached to sv.

=head4 int sv_payload_detach (SV* sv, const payload_marker_t* marker = NULL)

Removes payload from sv and returns number of payloads removed.

=head4 void rv_payload_attach (const SV* rv, void* ptr, const payload_marker_t* marker = NULL)

=head4 bool rv_payload_exists (const SV* rv, const payload_marker_t* marker = NULL)

=head4 void* rv_payload (const SV* rv, const payload_marker_t* marker = NULL)

=head4 int rv_payload_detach (const SV* rv, const payload_marker_t* marker = NULL)

Same as sv_* but operates on sv referenced by a given rv. Doesn't check if a given RV is valid.


=head2 SUPER/NEXT METHOD FUNCTIONS

=head4 SV* call_super (CV* cv, SV** args, I32 items, I32 flags = 0)

Calls super method from inside XS method. 'cv' is a pointer to currently running XS function (every XS function has this variable).
'args' and 'items' describes perl variables to pass to super method. If you want to passthrough all the arguments your XS function
received, pass '&ST(0)' and 'items'. 'flags' is passed to Perl's API call_method / call_sv as is. SUPER is always called in SCALAR
context. Returned SV* has its refcounter increased. If you don't need it, decrement it. If you don't need return value at all,
pass G_DISCARD in flags.

=head4 SV* call_next_method (CV* cv, SV** args, I32 items, I32 flags = 0)

Calls next method (C3 MRO). See "call_super" for argument details.

=head4 SV* call_next_maybe (CV* cv, SV** args, I32 items, I32 flags = 0)

Calls next method (C3 MRO). Return undef if no next method. See "call_super" for argument details.

=head4 SV* call_next (CV* cv, SV** args, I32 items, next_t type, I32 flags = 0)

Generic form of call_super/call_next_method/call_next_maybe. 'type' is either xs::NEXT_SUPER or xs::NEXT_METHOD or xs::NEXT_MAYBE.


=head2 TYPEMAP RELATED FUNCTIONS

=head4 SV* typemap_out_ref (SV* var)

Does what AV*, HV*, etc OUTPUT typemaps do. Creates RV to SV and returns it. If var is NULL, returns undef variable.

=head4 SV* typemap_out_oref (SV* var, const char* CLASS)

=head4 SV* typemap_out_oref (SV* var, SV* CLASS)

Does what OAV*, OHV*, etc OUTPUT typemaps do. Creates RV to SV, blesses it into CLASS and returns it.
If var is NULL, returns undef variable.

=head4 SV* typemap_out_optr (void* var, const char* CLASS)

=head4 SV* typemap_out_optr (void* var, SV* CLASS)

Does what T_OPTR OUTPUT typemap does. Creates IV from var's address, creates RV to IV, blesses it into CLASS and returns it.
If var is NULL, returns undef variable.

=head4 SV* typemap_out_oext (SV* self, void* var, const char* CLASS, payload_marker_t* marker = NULL)

=head4 SV* typemap_out_oext (SV* self, void* var, SV* CLASS, payload_marker_t* marker = NULL)

If self is an RV to a bless SV, just attaches var to it using marker as a key. If self is not NULL, but not an RV, then before
attaching, blesses it into CLASS, and creates an RV. If self is NULL, creates RV to undef. If marker is NULL, uses global default
marker (&xs::sv_payload_default_marker).
That means you are not able to store two or more pointers in an SV without passing markers.

Marker can be created by defining it as a global variable in your translation unit for example:

    static payload_marker_t my_marker;
    
    ...
    
    SV* object = xs::typemap_out_oext(NULL, new MyClass(), "My::Class", &my_marker);
    
If you want to have named markers, use 'sv_payload_marker'.

    SV* create_object (int arg) {
        MyClass* var = new MyClass(arg);
        static payload_marker_t* marker = xs::sv_payload_marker("MarkerForMyClass");
        return xs::typemap_out_oext(NULL, var, "My::Class", &marker);
    }

=head4 payload_marker_t* sv_payload_marker (const char* class_name)

Returns a marker for specified key. If no marker exists for that key, creates and returns it.

=head4 AV* typemap_in_av (SV* arg)

=head4 HV* typemap_in_hv (SV* arg)

=head4 IO* typemap_in_io (SV* arg)

=head4 CV* typemap_in_cv (SV* arg)

Treats arg as an RV to AV/HV/IO/CV and returns AV/HV/IO/CV*. If arg is NULL or arg is not an RV to AV/HV/IO/CV, returns NULL.

=head4 SV* typemap_in_osv (SV* arg)

=head4 AV* typemap_in_oav (SV* arg)

=head4 HV* typemap_in_ohv (SV* arg)
    
=head4 IO* typemap_in_oio (SV* arg)

Treats arg as an RV to a blessed AV/HV/IO/SV and returns AV/HV/IO/SV*. If arg is NULL or arg is not an RV to a blessed AV/HV/IO/SV,
returns NULL.

=head4 void* typemap_in_optr (SV* arg)

Treats arg as an RV to a blessed IV and returns an object stored in IV as void*. If arg is NULL or arg is not an RV to a blessed IV,
returns NULL.

=head4 void* typemap_in_oext (SV* arg, payload_marker_t* marker = NULL)

Treats arg as an RV to a blessed SV(any) and returns an object attached to SV with marker 'marker' as void*.
If arg is NULL or arg is not an RV to a blessed SV(any), or nothing attached with specified marker, returns NULL.
If marker is NULL, uses global default marker.



=head1 PERL FUNCTIONS

=head4 obj2hv ($obj)

=head4 obj2av ($obj)

Upgrades $obj to HASHREF or ARRAYREF.

$obj must be a valid reference to something lower than array or hash (undef, number, string, etc). Otherwise will croak.
If $obj is already of desired type, nothing is done.
 
=head4 sv_payload_attach ($target, $payload)

Attach $payload to $target. $target can be any l-value scalar. If $target has any $payload, it gets removed.

=head4 sv_payload ($target)

Returns payload attached to $target if any, otherwise undef.

=head4 sv_payload_exists ($target)

Returns true if $target has any payload.

=head4 sv_payload_detach ($target)

Removes payload from $target. Returns true if any payload has been removed.

=head1 CAVEATS

If module A binary depends on module B and module B updates and becomes binary incompatible, undefined behaviour may happen.
To solve this problem, one need to reinstall (rebuild) all modules that depend on module B. To help solving this problem,
Panda::Install automatically tracks these depedencies, warns and croaks if any binary depedencies became incompatible and
prints the list of modules to reinstall (rebuild).

=head1 AUTHOR

Pronin Oleg <syber@crazypanda.ru>, Crazy Panda, CP Decision LTD

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;

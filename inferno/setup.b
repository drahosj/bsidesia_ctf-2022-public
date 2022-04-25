implement Setup;

include "secrets.m";
include "routines.m";
include "sys.m";
include "draw.m";

sys : Sys;
routines : Routines;

Setup : module {
    init: fn(nil: ref Draw->Context, args: list of string);
};

init(nil: ref Draw->Context, args: list of string)
{
    sys = load Sys Sys->PATH;
    routines = load Routines "routines.dis";

    if (len args < 3) {
        sys->print("setup <flag> <module to use for key>\n");
        return;
    }
    
    args = tl args;
    flag := hd args;
    args = tl args;
    keymod := hd args;

    sys->print("flag: %s\n", flag);
    sys->print("Module with key: %s\n", keymod);

    #sys->print("hex(%s): %s\n", flag, routines->hex(array of byte flag));
    #sys->print("unhex(%s): %s\n", keymod, string routines->unhex(keymod));

    secrets := load Secrets keymod;
    sys->print("key: %s\n", secrets->key);

    f := routines->hex(routines->obfuscate(array of byte flag, secrets->key));
    sys->print("obfuscated flag: %s\n\n", f);
    f2 := string routines->obfuscate(routines->unhex(f), secrets->key);
    sys->print("Unobfuscated to test: %s\n", f2);

}

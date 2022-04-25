implement Test;

include "secrets.m";
include "routines.m";
include "sys.m";
include "draw.m";

sys : Sys;
routines : Routines;

Test : module {
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

    sys->print("hex input: %s\n", flag);
    sys->print("Module with key: %s\n", keymod);

    secrets := load Secrets keymod;
    sys->print("key: %s\n", secrets->key);

    f := routines->hex(
        routines->obfuscate(routines->unhex(flag), 
        secrets->key));
    sys->print("output: %s\n\n", f);

}

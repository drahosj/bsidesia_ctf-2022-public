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

    if (len args < 2) {
        sys->print("setup <module to use for secrets>\n");
        return;
    }
    
    args = tl args;
    keymod := hd args;

    sys->print("Module with key and flag: %s\n", keymod);

    secrets := load Secrets keymod;
    sys->print("hex input: %s\n", secrets->flag);
    sys->print("key: %s\n", secrets->key);

    f := routines->obfuscate(routines->unhex(secrets->flag), secrets->key);
    sys->print("output: %s\n\n", string f);

}

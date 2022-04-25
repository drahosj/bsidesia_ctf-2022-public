implement Fuego;

include "secrets.m";
include "routines.m";
include "sys.m";
include "draw.m";

sys : Sys;
routines : Routines;

Fuego : module {
    init: fn(nil: ref Draw->Context, args: list of string);
};

init(nil: ref Draw->Context, args: list of string)
{
    sys = load Sys Sys->PATH;
    routines = load Routines "routines.dis";

    secrets := load Secrets "secrets.dis";
    f := routines->obfuscate(routines->unhex(secrets->flag), secrets->key);
    sys->print("%s\n", string f);

}

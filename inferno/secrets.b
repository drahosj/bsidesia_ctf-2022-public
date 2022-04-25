implement Secrets;

include "sys.m";
include "draw.m";
include "routines.m";

Secrets: module {
    key: string;
    flag: string;
    init: fn(nil: ref Draw->Context, args: list of string);
};

key = "Ah yeah ah yeah ah yeah, yeah ah yeah ah yeah\nFuego";
flag = "731c06253b6d1a1145180d3e114500007f1f0c130d51";

hidden_key := "I was looking for some high-high-highs, yeah";
hidden_flag := "240410643f22140a051a0252080e0649050a320c4e011d1a";

sys : Sys;
routines : Routines;

init(nil: ref Draw->Context, args: list of string)
{
    sys = load Sys Sys->PATH;
    routines = load Routines "routines.dis";

    secrets := load Secrets "secrets.dis";
    f := routines->obfuscate(routines->unhex(hidden_flag), hidden_key);
    sys->print("%s\n", string f);

}

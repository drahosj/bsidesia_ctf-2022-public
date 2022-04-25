import std.stdio;
import std.conv;
import std.string;

import cstdio = core.stdc.stdio;

int main()
{
    cstdio.setbuf(cstdio.stdout, null);
    cstdio.setbuf(cstdio.stdin, null);
    int sum = 0;
    while (sum < 1944) {
        int n = readln().split(' ')[1].chomp.to!int;
        readln();
        if (sum + n <= 1944) {
            sum += n;
            writeln("k");
            stderr.writeln(readln());
        } else {
            writeln("s");
        }
    }

    return 0;
}

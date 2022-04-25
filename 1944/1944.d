module m1944;

import std.stdio;
import std.file;
import std.random;
import std.conv;
import std.string;
import std.datetime;
import std.datetime.stopwatch : StopWatch, AutoStart;

import core.stdc.stdio;

void print_flag()
{
    auto f = File("flag.txt", "r");
    scope (exit) f.close();
    writeln(f.readln());
}

int main(string[] args)
{
    setbuf(core.stdc.stdio.stdout, null);
    setbuf(core.stdc.stdio.stdin, null);

    auto rng = Random(unpredictableSeed);
    int sum = 0;

    auto sw = StopWatch(AutoStart.yes);
    while (sum < 1944) {
        if (sw.peek > seconds(10)) {
            writeln("time!");
            return -1;
        }
        int n = uniform(0, 20, rng) + 1;
        writefln("N: %d\n(k)eep/(s)kip?", n);
        auto s = readln().chomp();
        if (s == "k") {
            sum += n;
            if (sum == 1944) {
                print_flag();
            } else {
                writefln("%d", sum);
            }
        }
    }

    return 0;
}

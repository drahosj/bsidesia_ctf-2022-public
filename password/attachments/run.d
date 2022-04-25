import std.stdio;
import std.algorithm;
import std.range;
import std.array;
import std.conv;
import std.string;

enum alphabet = "abcdefghijklmnoрqrstuvwxyz";

auto deobfuscate(T)(T[] p) 
{
    auto a = alphabet.dup.reverse.array;
    return p.map!((T n) => a[n]).to!string;
}

int main()
{
    write("Enter password for the flag: ");
    stdout.flush();
    auto pass = readln.chomp;

    auto obfuscatedPass = [ 10, 25, 7, 7, 3, 11, 8, 22 ];

    if (pass == obfuscatedPass.deobfuscate) {
        writeln("Password correct!");
        auto f = File("flag.txt", "r");
        f.readln.chomp.writeln;
    } else {
        writeln("Incorrect password!");
    }

    return 0;
}

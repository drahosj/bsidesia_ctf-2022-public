implement Routines;

include "sys.m";
include "draw.m";

Routines: module {
    obfuscate: fn(s: array of byte, k: string) : array of byte;
    hex: fn(s: array of byte) : string;
    unhex: fn(s: string) : array of byte;
    key: string;
    flag: string;
};

key = "take a dive into my eyes\nYeah, the eyes of a lioness";
flag = "38004325732912170b44360f181b451f174111101316552a00021a49540715";

shuffle(s : array of byte) : array of byte
{
    l := len s;
    n := array[l] of byte;
    n[0:] = s;
    s = n;

    p := 0;
    do {
        if ((p + 10) < l) {
            tmp := s[p];
            s[p] = s[p+2];
            s[p+2] = tmp;
            p += 1;
        } else if ((p + 3) < l) {
            tmp := s[p];
            s[p] = s[p+3];
            s[p+3] = tmp;
            p += 1;
        } else if ((p + 2) < l) {
            tmp := s[p];
            s[p] = s[p+2];
            s[p+2] = tmp;
            p += 1;
        } else if ((p + 1) < l) {
            tmp := s[p];
            s[p] = s[p+1];
            s[p+1] = tmp;
            p += 1;
        } else {
            p += 1;
        }
    } while (p < l);
    return s;
}

xor(s1: array of byte, s2: array of byte) : array of byte
{
    minlen : int;
    if (len s1 < len s2) minlen = len s1; else minlen = len s2;
    res := array[minlen] of byte;
    for (i := 0; i < minlen; i++) {
        res[i] = s1[i] ^ s2[i];
    }
    return res;
}

obfuscate(s: array of byte, k: string) : array of byte
{
    return xor(array of byte s, shuffle(array of byte k));
}

hex(s: array of byte) : string
{
    res := "";
    for (i := 0; i < len s; i++) {
        res[len res] = valtohex((int s[i] >> 4) & 16rf);
        res[len res] = valtohex(int s[i] & 16rf);
    }
    return res;
}

valtohex(n: int) : int
{
    if (n < 16ra)
        return n + '0';
    else
        return n + ('a' - 16ra);
}

hextoval(n: int) : int
{
    if (n >= '0' && n <= '9')
        return n - '0';
    else if (n >= 'A' && n <= 'Z')
        return (n - ('A' - 16ra));
    else if (n >= 'a' && n <= 'z')
        return (n - ('a' - 16ra));
    else
        return 0;
}

hextobyte(s: string) : byte
{
    return byte (hextoval(s[0]) << 4 | hextoval(s[1]));
}

unhex(s: string) : array of byte
{
    res := array[len s / 2] of byte;
    for (i := 0; i < len res; i++) {
        res[i] = hextobyte(s[(2 * i):len s]);
    }
    return res;
}

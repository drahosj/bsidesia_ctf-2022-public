This is the "run compiled inferno code" challenge. There are three flags - two
optionally hidden.

What's provided:
3 compiled dis modules
two module headers which, while not actually necessary to run anything, give
a few more clues.

How it works:

The fuego module loads the flag (obfuscated) and key from Secrets, then using
the (un)obfuscate routine from Routines, prints the flag. Easy. Just have to
run 'fuego' in inferno

The first hidden flag:

the Secrets module also implements an init and, when run, does
basically the same thing but ends up printing a different flag

The third hidden flag:

The compiled Routines dis file can also be loaded as a Secrets module; it
exports a flag and a key as well. So you can either write your own test, or
actually just copy routines.dis over top of secrets.dis and then run
the original main module.

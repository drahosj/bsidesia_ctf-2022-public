Directory format (to make importing super easy)

/
|- chal1/
|  |- description.txt
|  |- flags.csv
|- chal2/
|  |- description.txt
|  |- flags.csv
|  |- attachments/
|     |- file1.elf
|  |- misc
|  |- code
|  |- notes.txt
|  |- ...
|- chal.../

When importing, the following will happen:

1. flags.csv will be read with the following format (headers=true)
creating flags in the DB
-
name,points,regexp,visible
Example Chal,10,SecDSM{test},true
Example Hidden Chal,20,SecDSM{test2},false

2. All of the non-hidden created flags will have
their description set to description.txt

3. all files in attachments will be uploaded to S3

4. all uploaded attachments will be attached to the non-hidden flags

Thus, it follows that to
a) create a normal, non-hidden flag with or without attachments
  -> put it in flags.csv, write description.txt, optionally add attachments
b) create multiple normal flags in the same directory (eg. shared source code 
  to generate multiple levels of a challenge
  -> put both flags in flags.csv, write a combined description
2. All of the non-hidden created flags will have
their description set to description.txt

3. all files in attachments will be uploaded to S3

4. all uploaded attachments will be attached to the non-hidden flags

Thus, it follows that to:
a) create a normal, non-hidden flag with or without attachments
  -> put it in flags.csv, write description.txt, optionally add attachments
b) create hidden flags (associated with any challenge or otherwise)
  -> put it in flags.csv and set visible=false
c) create multiple normal flags in the same directory (eg. shared source code 
  to generate multiple levels of a challenge and it makes sense to keep them
  together in the git repo)
  -> put both flags in flags.csv, write a combined description, combine
    attachments, then import and just clean things up in the DB afterwards
d) create a "parent" challenge that consists of subflags
  -> write an appropriate description.txt and/or attachments, then add the 
    "parent" challenge to flags.csv as unhidden, points=total number of points
    for the family, visible=true, but regexp=null. Then, add the actual subflags
    to flags.csv with any appropriate names and visible=false, points=points
    for that subflag

The parent/child is a bit of a hack, but the result is:

- The parent challenge will show up in "Unsolved Flags" with the description
and attachment(s). Its point value will be the stated points - the sum of its 
solved children (for that team). As the subflags are submitted, they will show
up (with their name and points) in "Solved Flags" for that team. Once the
remaining points for the parent reach 0, it will no longer show up in "Unsolved"

NOTE: You can still totally lie about the number of points available in a parent
challeng :)


== TL;DR ==
1. Create a folder for each challenge
2. Put the name,points,flag,hidden in flags.csv
3. Write description.txt and populate attachments
4. Add any hidden flags (whether a straight hidden bonus flag or "subflags"
   to flags.csv and set them as visible=false

see intro for an example for one standard flag and one bonus flag

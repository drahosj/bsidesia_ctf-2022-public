#! /usr/bin/env ruby

# Limbo appends the full path of the source .b file
# to the compiled .dis file. This can leak info.
#
# It also isn't even required by the Dis VM specification


# Solve this the lazy way
ARGV.each do |f|
  data = IO.read(f);
  i = data.length - 2;
  i -=1 while data[i] != "\u0000" 
  if data[i+1..] =~ /.*inferno.*/
    IO.write(f, data[..i])
  else
    puts "ERROR: End of '#{f}' doesn't look like a leaked path - skipping."
  end
end


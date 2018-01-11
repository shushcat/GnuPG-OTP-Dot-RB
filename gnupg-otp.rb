#!/usr/bin/env ruby

# https://tools.ietf.org/html/rfc4880#section-6.3
Mapping = ["A", "B", "C", "D", "E", "F", "G", "H", "I",
           "J", "K", "L", "M", "N", "O", "P", "Q", "R",
           "S", "T", "U", "V", "W", "X", "Y", "Z", "a",
           "b", "c", "d", "e", "f", "g", "h", "i", "j",
           "k", "l", "m", "n", "o", "p", "q", "r", "s",
           "t", "u", "v", "w", "x", "y", "z", "0", "1",
           "2", "3", "4", "5", "6", "7", "8", "9", "+",
           "/", "="]

Header = "-----BEGIN PGP PRIVATE KEY BLOCK-----"
Footer = "-----END PGP PRIVATE KEY BLOCK-----"

def print_help
  puts "Create dummy keys for safe remote storage of private keys."
  puts
  puts "Usage: gnupg-otp.rb <encrypt|decrypt> <private key|dummy key> <one time pad>"
  puts
  puts "Where the one time pad is a text file containing"
  puts "at least as many characters as the private key."
  exit
end

begin
  # Hidden recipients are assumed in determining slice length
  private_key = (File.open(ARGV[1]).read
                   .delete("\n")).slice(37..-36)
  one_time_pad = (File.open(ARGV[2]).read
                    .delete("\n")).slice(0..private_key.length)
rescue
  print_help
end

def armored_string_to_int_ary (armored_string)
  int_ary = []
  armored_string.split('').each do |char|
    if Mapping.member?(char) then
      int_ary << Mapping.index(char)
    else
      int_ary << Mapping.index("=")
    end
  end
  return int_ary
end

def int_ary_to_armored_string (int_ary)
  armored_string = []
  int_ary.each do |n|
    armored_string << Mapping[n]
  end
  return armored_string.join
end

def encrypt_pad (key_ary, pad_ary)
  key_ary.map.with_index {|n, i| (n+pad_ary[i])%65}
end

def decrypt_pad (key_ary, pad_ary)
  key_ary.map.with_index {|n, i| (n-pad_ary[i])%65}
end

if ARGV[0] == "encrypt" then
  puts Header + "\n\n"
  puts int_ary_to_armored_string(
         encrypt_pad(armored_string_to_int_ary(private_key),
                 armored_string_to_int_ary(one_time_pad)))
         .scan(/.{64}|.+/).join("\n")
  puts Footer
elsif ARGV[0] == "decrypt" then
  puts Header + "\n\n"
  puts int_ary_to_armored_string(
         decrypt_pad(armored_string_to_int_ary(private_key),
                 armored_string_to_int_ary(one_time_pad)))
         .scan(/.{64}|.+/).join("\n")
  puts Footer
else
  print_help
end

# this one is like your scripts with argv
def puts_two(*args)
  arg1, arg2 = args
  puts "arg1: #{arg1}, arg2: #{arg2}"
end
# ok, 
def puts_two_again(arg1, arg2)
  puts "arg1: #{arg1}, arg2: #{arg2}"
end

def puts_one(arg1)
  puts "arg1: #{arg1}"
end

def puts_none()
  puts "I got nothin'."
end

puts_two("Zed", "Shaw")
puts_two_again("dfd", "adfdfd")
puts_one("first")
puts_none()
puts_two_again "ddk", "d"

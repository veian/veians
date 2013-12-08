def prompt
  print ">"
end

puts "Please input any number you want:"
prompt; num = gets.chomp()
i = 0
numbers = []

while i < num.to_i
  puts "At the top i is #{i}"
  numbers.push(i)

  i += 1
  puts "Numbers now: #{numbers}"
  puts "At the bottom i is #{i}"
end

puts "The numbers: "

for num in numbers
  puts num
end

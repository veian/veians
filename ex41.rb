def prompt()
  print "> "
end

def death()
  quips = [
    "You died. You kinda suck at this.",
    "Nice job, you died ... jackass.",
    "Such a luser.",
    "I have a small puppy that's better at this."
  ]
  puts quips[rand(quips.length)]
  Process.exit(1)
end

def central_corridor()
  puts "central_corridor"
  
  prompt()
  action = gets.chomp()
  
  if action == "shoot"
    puts "shooot"
    return :death
  elsif action == "dodge"
    puts "dodge"
    return :death
  elsif action == "tell a joke"
    puts "tell a joke"
    return :laser_weapon_armory
  else
    puts "DOES NOT COMPUTE!"
    return :central_corridor
  end
end

def laser_weapon_armory()
  puts "laser_weapon_armory"
  
  code = "%s%s%s" % [rand(9) + 1, rand(9) + 1, rand(9) + 1]
  print "[keypad] > "
  guess = gets.chomp()
  guesses = 0
  
  while guess != code and guesses < 10
    puts "BZZZEDDD!"
    
    guesses += 1
    print "[keypad] > "
    guess = gets.chomp()
  end
  
  if guess == code
    puts "winnnnnn!"
    return :the_bridge
  else
    puts "lossssss!"
    return :death
  end
end

def the_bridge()
  puts "the_bridge"
  prompt()
  action = gets.chomp()
  
  if action == "throw the bomb"
    puts "throw the bomb"
    return :death
  elsif action == "slowly place the bomb"
    puts "slowly place the bomb"
    return :escape_pod
  else
    puts "DOES NOT COMPUTE!"
    return :the_bridge
  end
end

def escape_pod()
  puts "escape_pod"
  good_pod = rand(5) + 1
  print "[pod #] > "
  guess = gets.chomp()
  
  if guess.to_i != good_pod
    puts "not equal"
    return :death
  else
    puts "equals"
    Process.exit(0)
  end
end

ROOMS = {
  :death => method(:death),
  :central_corridor => method(:central_corridor),
  :laser_weapon_armory => method(:laser_weapon_armory),
  :the_bridge => method(:the_bridge),
  :escape_pod => method(:escape_pod)
}

def runner(map, start)
  next_one = start
  
  while true
    room = map[next_one]
    puts "\n----------"
    next_one = room.call()
  end
end

runner(ROOMS, :central_corridor)
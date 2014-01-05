class Game
  def initialize(args)
    @quips = [
      "You died. You kinda suck at this.",
      "Nice job, you died ... jackass.",
      "Such a luser.",
      "I have a small puppy that's better at this."
    ]
    
    @start = args
    
    puts "in init @start = " + @start.inspect
  end
  
  def prompt()
    print "> "
  end
  
  def play()
    puts "@start => " + @start.inspect
    
    next_room = @start
    
    while true
      puts "\n ---------"
      room = method(next_room)
      next_room = room.call()
    end
  end
  
  def death()
    puts @quips[rand(@quips.length())]
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
    print "#{code}[keypad] > "
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
    print "#{good_pod}[pod #] > "
    guess = gets.chomp()
    
    if guess.to_i != good_pod
      puts "not equal"
      return :death
    else
      puts "equals"
      Process.exit(0)
    end
  end
  
end

a_game = Game.new(:central_corridor)
a_game.play()
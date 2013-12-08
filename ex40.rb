cities = {
  'CA' => 'San Francisco',
  'MI' => 'Detroit',
  'FL' => 'Jacksonville'
}

cities['NY'] = 'New York'
cities['OR'] = 'Portland'

def find_city(map, state)
  
  if map.include? state
    return map[state]
  else
    return "Not found."
  end
  
end

cities[:find] = method(:find_city)

puts cities

while true
  print "State? (ENTER to quit) "
  state = gets.chomp
  
  break if state.empty?
  
  puts cities[:find].call(cities, state)
end
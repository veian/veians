a =  "我是个机器人".scan(/./).join("-")
b = "Ted from Familab has made a Raspberry Pi SNES hack with a difference.".scan(/\w+/)
puts b.join("----")
puts a

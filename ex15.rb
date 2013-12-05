# 从命令行中获取第一个参数，$0是文件本身
filename = ARGV.first
# 这是输入提示符
prompt = "> "
# 告诉File 打开一个文件
txt = File.open(filename)
# 输出这个文件名
puts "Here's your file: #{filename}."
# txt.read() 告诉txt执行read方法，读出内容。并打印出来
puts txt.read()
txt.close()

# 打印
puts "Type the filename again:"
# 输出 输入提示符
print prompt
# 通过STDIN 获取到 用户输入的值
file_again = STDIN.gets.chomp()
# 告诉File 执行打开文件命令
txt_again = File.open(file_again)
# 打印出 内容
puts txt_again.read()
txt_again.close()

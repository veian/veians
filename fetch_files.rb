require 'open-uri'
require 'uri'
require 'fileutils'

uri = 'http://i3.dpfile.com/m/js/app/dianping/slide.js'
version = '/Users/zhubin/Dropbox/code/i1.dpfile.com/version.tuan.js'

# 创建文件夹
def makeDIR(f)
  root_path = '/Users/zhubin/Dropbox/code/dianping'
  u = URI(f)
  path = u.path
  filename = File.basename(path)
  path_index = path.index filename
  
  full_path = root_path + path[0...path_index]
  file = full_path + filename
  puts path
  puts full_path
  
  if File.exists?full_path
    puts '目录已存在'
  else
    FileUtils.makedirs(full_path)
    puts '创建目录成功'
  end
  
  puts file
  puts '==========='
  if file.empty?
    puts path + '文件已经存在'
  else
    outfile = File.new(full_path + filename, 'w')
    begin
      open(f){|file|
        outfile.puts file.read()
      }
    rescue Exception => e
      puts f + '文件不存在'
    end
  end
end

# File.open(version).each do |line|
#   makeDIR(line)
# end

makeDIR(uri)
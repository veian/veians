#定义一个模块,打印日志  
module Log  
  def Log.i(msg)  
    print "[INFO]#{msg}/n"  
  end  
  def Log.e(msg)  
    print "[ERROR]#{msg}/n"  
  end  
end  
#定义一个类，用于封装加入到队列中的url，包含了url的链接深度和待保存的文件名的信息  
class UrlObj  
  attr_accessor :url,:depth,:save_name  
  def initialize(url,depth,save_name)  
    @url=url  
    @save_name=save_name  
    @depth=depth  
  end  
  
  def info#解析得到url中的信息  
    return @info if @info  
    begin  
      @info=URI.parse(@url)  
      return @info  
    rescue Exception=>e  
      Log.e e  
      return nil  
    end  
  end  
  
  def domain#获取url中的域名  
    if @domain  
      return @domain  
    elsif !info  
      Log.e("#{@url}'s host is nil")  
      return nil  
    elsif !info.host  
      Log.e("#{@url}'s host is nil")  
      return nil  
    else  
      return info.host[//w+/./w+$/]  
    end  
  end  
end  


class WebSnatcher  
  THREAD_SLEEP_TIME=0.5#定义常量，线程睡眠时间  
  HTTP_RETRY_TIMES=3#设置打开链接的重试次数  
  
#初始化类变量和各种设置参数  
  def initialize(opt={})  
    @url_to_download=[]#待下载的url容器  
    @url_to_download_count=0#待下载的url数量  
    @html_name_counter=0#html文件保存数器  
    @file_name_counter=0#其他文件的保存计数器  
    @bad_urls=[]#坏的链接容器  
    @url_history={}#url历史容器，避免重复下载  
    @file_history={}#其他文件容器，避免重复下载  
    @thread_count=opt[:thread_count]||=10#设置线程个数  
    @mutex=Mutex.new  
    @dig_depth_limit=opt[:depth]||=2#设置链接最大深度  
     #获取并设置工作路径  
    @work_path=opt[:work_path]||File.dirname(__FILE__)+"/output/"#  
    @other_file_path=@work_path+"others/"  
    FileUtils.mkdir_p @other_file_path unless File.directory?(@other_file_path)  
    Log.i "Downloaded files will save to #{@work_path}"  
    #设置文件下载大小限制  
    @max_file_size=opt[:max_file_size]||nil  
    @min_file_size=opt[:min_file_size]||nil  
    #匹配合适的url正则表达式的容器  
    @include_url_matcher  
    #匹配不合适的url正则表达式的容器  
    @exclude_url_matcher=[]  
    #设置需要下载的文件类型，没有定义参数则下载全部类型的文件  
    @need_type={}      
    if opt[:file_limit]  
      opt[:file_limit].each { |filetype|  
        @need_type[filetype]=true  
      }  
    else  
      @need_all=true  
    end  
  end  
  
  #定义了两个方法用于添加匹配url的正则表达式  
  def append_include_url_matcher(regexp)  
    @include_url_matcher<<regexp if regexp.instance_of?(Regexp)  
    return self  
  end  
  def append_exclude_url_matcher(regexp)  
    @exclude_url_matcher<<regexp if regexp.instance_of?(Regexp)  
    return self  
  end  
    
  #get_url_to_download和add_url_to_download两个方法用于多线程  
  #保存和获取url下载任务时进行同步。  
  def get_url_to_download  
    @mutex.synchronize do  
      if @url_to_download_count>0  
        url=@url_to_download.shift  
        @url_to_download_count-=1  
        return url  
      else  
        return nil  
      end  
    end  
  end  
    
  def add_url_to_download(url)  
    @mutex.synchronize do  
      @url_to_download.push(url)  
      @url_to_download_count+=1  
    end  
  end  
  
  #将一个已经处理的url加入到历史,value是保存到本地的文件名。  
  def add_url_to_history(url,save_name)  
    @url_history[url]=save_name  
  end  
  
  
  #amind_url是一个很重要的方法，同时也是最需要改进的地方。  
  #由于HTML文档中给出的很多的链接往往都是相对链接或是简写，有些是./xxxx.xx的  
  #有些是../xxx.xx的，还有/xxxx.xx的，等等。在下载这些链接的时候需要将它们转化为  
  #完整的url格式才行，下面的amend_url覆盖了一些超链接方式，还有一些方式没有实现。  
  #如果有遇到没有覆盖的，再加上即可。  
  
  
  def amend_url(url,ref)  
    return nil unless url  
    return url if url=~/^http:////.+/  
    url=url.sub(/#/w+$/, "")  
    return amend_url($1,ref) if url=~/^javascript:window/.open/(['"]{0,1}(.+)['"]{0,1}/).*/i#<a href="javascript:window.open(" mce_href="javascript:window.open("xxxx")">  
    return nil if url=~/javascript:.+/i  
    return "http://"+url if url=~/^www/..+/#www.xxxxx.com/dddd  
    return "http://"+ref.info.host+url if url=~/^//.+/#root path url  
    #simple filename like 123.html  
    return ref.url.sub(///[^//]*$/,"/#{url}") if url=~/^[^//^/.].+/    
    if url=~/^/.//(.+)/ #./xxxxxx.jpg  
      return ref.url.sub(///[^//]+$/,"/#{$1}")  
    end  
    if url=~/^/././/(.+)/ #../xxxxxxx.jpg  
      return ref.url.sub(////w+//[^//]*$/, "/#{$1}")  
    end  
    nil  
  end  
  
  
  #获取一个保存到本地的文件名  
  def get_html_save_name  
    @hnm||=Mutex.new  
    @hnm.synchronize {  
      @html_name_counter+=1  
      return "#{@html_name_counter}.html"  
    }  
  end  
  
  def get_file_save_counter  
    @fnl||=Mutex.new  
    @fnl.synchronize{  
      return @file_name_counter+=1  
    }  
  end  
  
  #match_condition?是另外一个非常重要的方法，它用于判断一个url是否符合条件待下载的条件  
  #它是确保抓取准确的最关键因素，目前我暂且设计成用一个匹配正则表达式数组  
  #和一个不匹配正则表达式数组来限定，同时要求url的域名必须相同，希望它最起码不要跳到   
  #网站以外的地方去了。另外就是坏的链接也被排除在外了。  
  #这个方法的可以根据抓取的需要进行相应修改。  
  
  
  def match_condition?(url_obj)  
    @include_url_matcher.each{|rep|  
      return true if url_obj.url=~rep  
    }  
    @exclude_url_matcher.each{|rep|  
      return false if url_obj.url=~rep  
    }  
    return false if @bad_urls.include?(url_obj.url)  
    if !(@base_url_obj.domain)||@base_url_obj.domain!=url_obj.domain  
      return false  
    else  
      return true  
    end  
  end  
  #该方法用于将文本内容保存到文件中  
  def write_text_to_file(path,content)  
    File.open(path, 'w'){|f|  
      f.puts(content)  
    }  
    Log.i("HTML File have saved to #{path}")  
  end  
  #该方法用于将远程资源保存到本地  
  def download_to_file(_url,save_path)  
    return unless _url  
    begin  
      open(_url) { |bin|  
        size=bin.size  
        #判断文件大小限制  
        return if @max_file_size&&size>@max_file_size||@min_file_size&&size<@min_file_size  
        Log.i("Downloading: #{_url}|sze:#{size}")  
        File.open(save_path,'wb') { |f|  
          while buf = bin.read(1024)  
            f.write buf  
            STDOUT.flush  
          end  
        }  
      }  
    rescue Exception=>e  
      Log.e("#{_url} Download Failed!"+e)  
      return  
    end  
    Log.i "File has save to #{save_path}!!"  
  end  
  
  #处理一个url任务  
  def deal_with_url(url_obj)  
    Log.i "Deal with url:#{url_obj.url};depth=#{url_obj.depth}"  
    return unless url_obj.instance_of?(UrlObj)  
    retry_times=HTTP_RETRY_TIMES  
    content=nil  
    #失败后重试，一共3次  
    0.upto(HTTP_RETRY_TIMES) { |i|  
      begin  
        return unless url_obj.info  
        Net::HTTP.start(url_obj.info.host,url_obj.info.port)  
        content=Net::HTTP.get(url_obj.info)  
        retry_times-=1  
        break  
      rescue  
        next if i<HTTP_RETRY_TIMES#stop trying until has retry for 5 times  
        Log.i "Url:#{url_obj.url} Open Failed!"  
        return  
      end  
    }  
    Log.i "Url:#{url_obj.url} page has been read in!"  
    return unless content  
    #如果该链接的深度小于限定深度或是本次抓取未限定深度:@dig_depth_limit==-1  
    #则分析该文档中的超链接  
    if url_obj.depth<@dig_depth_limit||@dig_depth_limit==-1  
      urls = content.scan(/<a[^<^{^(]+href="([^>^/s]*)"[^>]*>/im)  
      urls.concat content.scan(/<i{0,1}frame[^<^{^(]+src="([^>^/s]*)"[^>]*>/im)  
      urls.each { |item|  
        anchor=item[0][/#/w+/]#deal with the anchor  
        anchor="" unless anchor  
        full_url=amend_url(item[0],url_obj)  
        next unless full_url  
        #如果该链接已存在，则直接替换  
        if @url_history.has_key?(full_url)  
          #替换文档中的超链接  
          content.gsub!(item[0],@url_history.fetch(full_url)+anchor)  
        else#add to url tasks  
          #if match the download condition,add to download task  
          save_name=get_html_save_name  
          new_url_obj=UrlObj.new(full_url, url_obj.depth+1,save_name)  
          if match_condition?(new_url_obj)  
            Log.i "Add url:#{new_url_obj.url}"  
            add_url_to_download new_url_obj  
            #替换文档中的超链接  
            content.gsub!(item[0], save_name+anchor)  
            add_url_to_history(full_url,save_name)  
          end  
        end  
      }  
    end  
  
    #下载HTML文档中的其他文件  
    files=[]  
    #search for image  
    files.concat content.scan(/<img[^<^{^(]+src=['"]{0,1}([^>^/s^"]*)['"]{0,1}[^>]*>/im) if @need_type[:image]||@need_all  
    #search for css  
    files.concat content.scan(/<link[^<^{^(]+href=['"]{0,1}([^>^/s^"]*)['"]{0,1}[^>]*>/im) if @need_type[:css]||@need_all  
    #search for javascript  
    files.concat content.scan(/<script[^<^{^(]+src=['"]{0,1}([^>^/s^"]*)['"]{0,1}[^>]*>/im) if @need_type[:js]||@need_all  
      
    files.each {|f|  
      full_url=amend_url(f[0],url_obj)  
        
      next unless full_url  
      base_name=File.basename(f[0])#get filename  
      base_name.sub!(//?.*/,"")  
      full_url.sub!(//?.*/,"")  
      #      unless base_name=~/[/.css|/.js]$/  
      base_name="#{get_file_save_counter}"+base_name  
      #      end  
      if @file_history.has_key?(full_url)  
        filename=@file_history[full_url]  
        #替换链接  
        content.gsub!(f[0],"others/#{filename}")  
      else  
        download_to_file full_url,@other_file_path+base_name  
        content.gsub!(f[0],"others/#{base_name}")  
        @file_history[full_url]=base_name  
        #        add_url_to_history(full_url,base_name)  
      end  
      files.delete f  
    }  
    #保存HTML文档  
    if @need_type[:html]||@need_all  
      write_text_to_file(@work_path+url_obj.save_name, content)  
      Log.i "Finish dealing with url:#{url_obj.url};depth=#{url_obj.depth}"  
    end  
  end  
  
  
  #抓取执行的方法  
  def run(*base_url)  
    @base_url=base_url[0] if @base_url==nil  
    Log.i "<---------START--------->"  
    @base_url_obj=UrlObj.new(@base_url,0,"index.html")  
    m=Mutex.new  
    threads=[]  
    working_thread_count=0  
    #开启线程  
    @thread_count.times{|i|  
      threads<<Thread.start() {  
        Log.i "Create id:#{i} thread"  
        loop do  
          url_to_download=get_url_to_download  
          if url_to_download  
            m.synchronize {  
              working_thread_count+=1  
            }  
            begin  
              deal_with_url url_to_download  
            rescue Exception=>e  
              Log.e "Error: " +e  
              @bad_urls.push(url_to_download.url)  
            end  
            m.synchronize {  
              working_thread_count-=1  
            }  
          else  
            sleep THREAD_SLEEP_TIME  
          end  
        end  
      }  
    }  
    #创建一个monitor线程用于监视抓取情况，同时到任务结束时终止程序运行  
    wait_for_ending=false  
    monitor=Thread.start() {  
      loop do  
        sleep 2.0  
        Log.i "Working threads:#{working_thread_count}|Ramain Url Count:#{@url_to_download_count}"  
        next unless wait_for_ending  
        #当出于工作状态的线程数量为0，同时链接任务为空时，结束程序  
        if @url_to_download_count==0 and working_thread_count==0  
          Log.i "Finish downloading,Stoping threads..."  
          threads.each { |item|  
            item.terminate  
          }  
          Log.i("All Task Has Finished")  
          break  
        end  
      end  
      Log.i "<---------END--------->"  
    }  
    #主线程join前处理第一个链接，以便添加最初的任务  
    deal_with_url @base_url_obj  
    wait_for_ending=true  
    Log.i "main thread wait until task finished!"  
    #main thread wait until task finished!  
    monitor.join  
  end  
end  
  
#1.Linux c函数参考  
#snatcher=WebSnatcher.new(:work_path=>"E:/temp/",:depth=>2)  
#snatcher.append_exclude_url_matcher(/http:////man/.chinaunix/.net//{0,1}$/i)  
#snatcher.run("http://man.chinaunix.net/develop/c&c++/linux_c/default.htm")  
  
  
  
#2.ruby参考  
snatcher=WebSnatcher.new(:work_path=>"E:/temp/",:depth=>2)  
snatcher.run("http://www.kuqin.com/rubycndocument/man/index.html")  
  
  
#3.mm picture  
#snatcher=WebSnatcher.new(:file_limit=>[:image],:min_file_size=>50000,:depth=>-1,:thread_count=>20,:work_path=>"E:/mm/")  
#snatcher.run("http://www.tu11.cc/")#snatcher.run("http://www.sw48.com/")#snatcher.run("http://www.siwameinv.net/")  

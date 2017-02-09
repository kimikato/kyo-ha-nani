#/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'wikipedia'
require 'date'
require 'open_jtalk'

Wikipedia.Configure {
  domain  'ja.wikipedia.org'
  path    'w/api.php'
}

today = Date.today.strftime("%-m月%-d日")
today_message_file = "message_#{Date.today.strftime("%Y%m%d").to_s}.wav"

page = Wikipedia.find( today )

summary = page.summary
              .gsub(/（[^）]*）/, "")
              .gsub(/#{today}/,"今日")
              .gsub(/(\r\n|\r|\n|\f)/,"")
text = page.text

fictional_flag = 0
message = ""
birth  = Array.new
events = Array.new

text.each_line { |line|
  line = line.chomp!
  next if line =~ /^$/

  if line =~ /^\=+/
    case line
    when /誕生日/
      if line =~ /フィクション/
        fictional_flag = 1
      else
        fictional_flag = 0
      end
    when /できごと/
      if line =~ /フィクション/
        fictional_flag = 2
      else
        fictional_flag = 0
      end
    else
        fictional_flag = 0
    end
  else
    
    if fictional_flag != 0
      year = line.split(" - ")[0].to_s
      line = (line.split(" - ")[1].to_s).split("、").reverse.join("、")
      case fictional_flag
      when 1
        # 誕生日
        if year.include?("生年不明")
          birth << line + "さん"
        else
          birth << year + "生まれの" + line + "さん"
        end
      when 2
        # できごと
        if year.include?("不明")
          event << line
        else
          event << ( year + "、" + line )
        end
      else
      end
    end
  end
}



message += "今日の誕生日は、" + birth.sample(2).join("、") + "のみなさんです。" unless birth.empty?
message += "また、" + events.sample(2).joins("、") + "、がおこりました。" unless events.empty?
message += "それでは、今からラジオ体操をはじめます。"

OpenJtalk.load(OpenJtalk::Config::Mei::NORMAL) do |openjtalk|
  header, data = openjtalk.synthesis(openjtalk.normalize_text(message.encode("UTF-8")))

  OpenJtalk::WaveFileWriter.save(today_message_file, header, data)
end

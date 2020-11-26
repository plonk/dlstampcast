#!/usr/bin/env ruby
require 'open-uri'
require 'json'
require 'fileutils'

def print_usage
  STDERR.puts("#$0 ROOM_NUMBER")
end

def dlstamp(stamp)
  STDERR.puts("Downloading stamp id #{stamp['id']}")
  
  bn = File.basename(stamp["name"])
  if File.exist?("cache/#{bn}")
    STDERR.puts("Cache HIT")
  else
    STDERR.puts("Cache MISS")
    begin
      system("wget", "-q", "-O", "/tmp/#{bn}", stamp["name"]) or fail "wget"
      system("cp", "-p", "/tmp/#{bn}", "cache/#{bn}") or fail "cp"
    ensure
      FileUtils.rm_f "/tmp/#{bn}"
    end
  end
  tags = stamp["tags"].map { |t| t["text"] }
  if tags.empty?
    tags = ["_notags"]
  end
  ext = File.extname(bn)
  tags.each do |t|
    t = t.encode("CP932", replace: '_')
    system("mkdir", "-p", "room/#{t}") or fail "mkdir -p"
    system("cp", "-pv", "cache/#{bn}", "room/#{t}/#{stamp['id']}#{ext}") or fail "cp -v"
  end
end

def main
  if ARGV.size != 1
    print_usage
    exit 1
  end

  room = ARGV[0].to_i
  store = {"stamps" => []}
  done = false
  page = 1
  while !done
    STDERR.puts("READING PAGE #{page} ...")
    open("https://stamp.archsted.com/api/v1/rooms/#{room}/stamps/guest?page=#{page}&sort=all") do |f|
      js = f.read
      data = JSON.parse(js)

      if data["stamps"].empty?
        done = true
      else
        store["stamps"].concat(data["stamps"])
      end
    end
    page += 1
  end

  FileUtils.mkdir_p("cache/")

  FileUtils.rm_rf("room/")
  FileUtils.mkdir_p("room/")
  
  File.open("room/stamps.json", "w") do |f|
    f.write(JSON.dump(store))
  end

  store["stamps"].each do |stamp|
    dlstamp(stamp)
  end

  FileUtils.rm_f("room#{room}.zip")
  system("zip", "-r", "-0", "room#{room}.zip", "room/")

  FileUtils.mkdir_p "public/archives"
  FileUtils.mv("room#{room}.zip", "public/archives/room#{room}.zip")
ensure
  FileUtils.rm_rf "room/"
end

if __FILE__ == $0
  main
end


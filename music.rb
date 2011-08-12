#!/usr/bin/ruby

require 'socket'

MUSIC_FILE = "~/.music"

VLC_EXEC = "/Applications/VLC.app/Contents/MacOS/VLC"
VLC_SOCKET = "/tmp/vlc.sock"
VLC_PID_FILE = "/tmp/vlc.pid"

MUSIC_PATH = File.expand_path(MUSIC_FILE)

class VLC

  class << self
    attr_accessor :socket_path
    attr_accessor :program_path
    attr_accessor :pid_path
  end
  
  def self.play(url)
    start unless running?
    self.command('clear')
    self.command("add #{url}")
  end
  
  def self.stop
    self.command('stop') if running?
  end
  
  def self.resume
    self.command('play') if running?
  end
  
  def self.quit
    self.command('quit') if running?
  end
  
  def self.running?
    return false unless File.exist?(self.pid_path)
    pid = File.read(self.pid_path)
    begin
      Process.kill(0, pid.to_i)
    rescue Errno::ESRCH
      File.delete(self.pid_path)
      return false
    end
    return true
  end
  
  def self.socket_exists?
    File.exist?(self.socket_path)
  end
  
  def self.start
    system("#{program_path} --daemon -I oldrc --rc-unix=#{socket_path} --rc-fake-tty --pidfile=#{pid_path}")
    while !running? do
      sleep(0.5)
    end
  end
  
  def self.command(cmd)
    socket.puts(cmd)
  end
  
  def self.socket
    @socket ||= UNIXSocket.new(socket_path)
  end
  
end

VLC.program_path = VLC_EXEC
VLC.socket_path = VLC_SOCKET
VLC.pid_path = VLC_PID_FILE

unless File.exist?(VLC_EXEC)
  puts "Expected to find VLC program at #{VLC_EXEC}, it wasn't there. Please install VLC from: http://www.videolan.org"
  exit
end

unless File.exist?(MUSIC_PATH)
  File.open(MUSIC_PATH, 'w') do |f|
    f.puts("te: http://www.di.fm/mp3/techno.pls\n")
    f.puts("tr: http://www.di.fm/mp3/trance.pls\n")
    f.puts("vt: http://www.di.fm/mp3/vocaltrance.pls\n")
  end
end

music = Hash[*File.read(MUSIC_PATH).split("\n").collect { |l| name, *url = l.split(':'); [name.strip, url.join(':').strip]}.flatten]

if ARGV[0] == 'quit'
  VLC.quit
  exit
end

if ARGV[0] == 'stop' || ARGV[0] == 'pause'
  VLC.stop
  exit
end

if ARGV[0] == 'resume'
  VLC.resume
  exit
end

if ARGV[0].nil?
  puts "Available streams:"
  music.each do |k,v|
    puts "#{k} (#{v})"
  end
  puts ""
  puts "- To play the first one: music #{music.keys.first}"
  puts "- To stop: music stop"
  puts "- To resume: music resume"
  puts "- To quit: music quit"
  puts ""
  exit
end

if music.has_key? ARGV[0]
  VLC.play(music[ARGV[0]])
  exit
else
  puts "Unknown command or stream '#{ARGV[0]}'"
  exit
end


require 'sinatra'

$JOB = {}

before do
  if $JOB[:pid]
    r = Process.waitpid($JOB[:pid], Process::WNOHANG)
    if r
      $JOB = {}
    end
  end
end

get '/' do
  erb :index
end

get '/goroom' do
  no = params[:no]
  redirect to("/rooms/#{no}")
end

get '/rooms/:id' do
  erb :room
end

class Sendfile
  BUFSIZE = 1024 * 1024

  def initialize(path)
    @f = File.open(path, "rb")
  end
  
  def each
    while data = @f.read(BUFSIZE)
      yield data
    end
  ensure
    @f.close
  end
end

get '/dl/:id' do
  unless File.exist? "public/archives/room#{params[:id]}.zip"
    halt 404, "archive not found"
  end
  redirect "http://neko.ddns.net/archives/room#{params[:id]}.zip"
end

get '/build/:id' do
  halt 503, "Another job is running" if $JOB[:pid]
  no = params[:id].to_i
  unless no > 0
    halt 400, 'Bad room number'
  end
  pid = spawn("ruby main.rb #{no}")
  $JOB = { pid: pid, room: no }
  redirect to("/rooms/#{no}")
end

run Sinatra::Application

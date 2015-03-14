puts "Loading...\n\n"

require 'CSV'
require 'email_verifier'
require_relative 'lookup'

first_name  = nil
last_name   = nil
middle_name = nil
host        = nil

class MyLogger
  def initialize(buffer=$stdout)
    @buffer = buffer
  end

  def <<(item)
    @buffer << item+"\n"
  end
end

if ENV['PORT']
  puts "STARTING SERVER"

  require 'sinatra'
  helpers { include Lookup }

  get '/discover' do
    stream do |out|
      wrapped_out = MyLogger.new(out)
      wrapped_out << '<pre>'

      first_name = params[:f]
      last_name  = params[:l]
      middle_name = params[:m]
      host        = params[:d]

      res = lookup_by_name f: first_name, m: middle_name, l: last_name, d: host, out: wrapped_out
    end
  end
else
  puts "RUNNING INLINE"

  include Lookup

  ARGV.each_with_index do |k, i|
      v = ARGV[i+1]
      case k
      when '-f'
          first_name  = v
      when '-l'
          last_name   = v
      when '-m'
          middle_name = v
      when '-d'
          host        = v
      end
  end

  mylogger = MyLogger.new

  lookup_by_name f: first_name, m: middle_name, l: last_name, d: host, out: mylogger
end

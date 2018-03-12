#!ruby --encoding utf-8:utf-8
# coding: utf-8

require_relative 'interpreter'

if ARGV.size == 0
    puts "Usage: ruby wumpus.rb [-dD] source.wumpus"
    exit
end

case ARGV[0]
when "-d"
    debug_level = 1
when "-D"
    debug_level = 2
else
    debug_level = 0
end

if debug_level > 0
    ARGV.shift
end

source = File.read(ARGV.shift)

wumpus = Interpreter.new(source, debug_level)

begin
    wumpus.run
rescue => e
    wumpus.print_debug_info
    $stderr.puts e.message
    $stderr.puts e.backtrace
end
#!/usr/bin/env ruby

require 'socket'

# ensure that output is flushed after each write (require when stdout is redirected to a file)
STDOUT.sync = true

port = ARGV[0]
server = TCPServer.new(port)
puts "server started on port #{port}"
loop do
  Thread.start(server.accept) do |client|
       line = client.gets
       if line.start_with?('GET /') && !line.start_with?('GET /favicon.ico') then
         puts "responding to: "+line
         client.print line
         client.close
       else
         puts "ignoring request: "+line
       end
 end
end

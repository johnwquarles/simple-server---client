require 'socket'
require 'json'

def send_request(request)
  host = 'localhost'
  port = 2000
  
  socket = TCPSocket.open(host, port)
  socket.print(request)
  response = socket.read
  headers, body = response.split("\r\n\r\n", 2)
  print body + "\n"
end

def user_get()
  puts "---------------------", "Please enter the name of the file you'd like to GET", "---------------------"
  user_input = gets.chomp
  puts "---------------------"
  
  "GET /#{user_input} HTTP/1.0\n" +
  "From: someuser@tinybrowser.com\n" +
  "User-Agent: TinyBrowser/1.0\n" +
  "\r\n\r\n"
end

def user_post()
  path = "/thanks.html"
  
  puts "---------------------", "Let's make a POST request", "---------------------"
  puts "Your name, dear Viking?"
  name = gets.chomp
  puts "And your e-mail address?"
  email = gets.chomp
  puts "---------------------"
  hash = {:viking => {:name=>name, :email=>email}}
  to_send = hash.to_json
  "POST #{path} HTTP/1.0\n" +
  "From: someuser@tinybrowser.com\n" +
  "User-Agent: TinyBrowser/1.0\n" +
  "Content-Type: text/json\n" +
  "Content-Length: #{to_send.size}\r\n\r\n" + 
  "#{to_send}"
end

puts "---------------------", "Welcome to Tiny Browser"  
loop do
  puts "---------------------", "Would you like to:"
  puts "1. GET a file"
  puts "2. POST form data"
  puts "3. EXIT", "---------------------"
  response = gets.chomp
  case response
  when "1"
    send_request(user_get())
  when "2"
    send_request(user_post())
  when "3"
    exit
  end
end
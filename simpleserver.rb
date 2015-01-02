require 'socket'
require 'json'

# I like the hash below for determining file extensions. Thank you https://practicingruby.com/articles/implementing-an-http-file-server
# via James MacIvor.

CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'rb' => 'text/ruby',
  'png' => 'image/png',
  'jpg' => 'image/jpeg',
}

DEFAULT_CONTENT_TYPE = 'application/octet-stream'

def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

def get_html(path)
  content = File.read(path)
end

def substitute_html(params)
  file = "thanks.html"
  
  html = File.read(file)
  insert_html = ""
  params.values.each {|value| value.each {|key, value| insert_html += "<li>#{key.capitalize}: #{value}</li>"} }
  html.gsub("<%= yield %>", insert_html)
end

server = TCPServer.open(2000)

loop {
  
  Thread.start(server.accept) do |client|
    
    request = client.read_nonblock(256)
    request_lines = request.split("\n")
    verb = request_lines[0].split(" ")[0]
  
    case verb
    when "GET"
      path = "." + request_lines[0].split(" ")[1]
      if File.exist?(path)
        client.print "HTTP/1.0 200 OK\r\n" 
        client.print "Date: #{Time.now.utc.strftime('%a, %d %b %Y %H:%M:%S')} GMT\r\n"
        client.print "Content-Type: #{content_type(path)}\r\n"
        client.print "Content-Length: #{File.size(path)}\r\n"
        client.print "\r\n"
        client.print get_html(path)
      else
        client.print "HTTP/1.0 404 Not Found\r\n"
        client.print "\r\n"
        client.print "404 Error! The requested page cannot be found."
      end
    when "POST"
      params = JSON.parse(request_lines[-1])
      html = substitute_html(params)
      client.print "HTTP/1.0 200 OK\r\n"
      client.print "\r\n"
      client.print html
    end
  
    client.close
  end
}
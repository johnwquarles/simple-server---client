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

def get_path(header_lines)
  "." + header_lines[0].split(" ")[1]
end

server = TCPServer.open(2000)

loop {
  
  client = server.accept
  header = ""
  while line = client.gets
    header += line
    break if header =~ /\r\n\r\n$/
  end
    
    header_lines = header.split("\n")
    verb = header_lines[0].split(" ")[0]
    path = get_path(header_lines)
    
    case verb
    when "GET"
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
      if File.exist?(path)
        # parse out the size, in bytes, of the request body from the header
        body_size = header_lines[-2].split(" ")[1].to_i
        # and read exactly that many bytes out of the socket
        body = client.read(body_size)
        params = JSON.parse(body)
        html = substitute_html(params)
        client.print "HTTP/1.0 200 OK\r\n"
        client.print "\r\n"
        client.print html
      else
        client.print "HTTP/1.0 404 Not Found\r\n"
        client.print "\r\n"
        client.print "404 Error! The POST request is looking for a nonexistant file"
      end
    end
  
    client.close
}
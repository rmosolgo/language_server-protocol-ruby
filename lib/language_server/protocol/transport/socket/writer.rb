# frozen_string_literal: true

module LanguageServer
  module Protocol
    module Transport
      module Socket
        class Writer
          def initialize(socket)
            @socket = socket
          end

          def write(response_hash)
            response_str = response_hash.merge(
              jsonrpc: "2.0"
            ).to_json

            headers = { "Content-Length" => response_str.bytesize }
            headers.each do |k, v|
              @socket.print "#{k}: #{v}\r\n"
            end
            @socket.print "\r\n"
            @socket.print response_str
            @socket.flush
          end
        end
      end
    end
  end
end

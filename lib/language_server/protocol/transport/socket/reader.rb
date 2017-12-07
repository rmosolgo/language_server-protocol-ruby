# frozen_string_literal: true
module LanguageServer
  module Protocol
    module Transport
      module Socket
        class Reader
          def initialize(socket)
            @socket = socket
          end

          def each_message(&block)
            header_parsed = false
            content_length = nil
            buffer = "".dup

            while char = @socket.getc
              buffer << char

              if !header_parsed
                if buffer[-4..-1] == "\r\n" * 2
                  content_length = buffer.match(/Content-Length: (\d+)/i)[1].to_i
                  header_parsed = true
                  buffer.clear
                end
              elsif buffer.bytesize == content_length
                request = JSON.parse(buffer, symbolize_names: true)
                block.call(request)
                header_parsed = false
                buffer.clear
              end
            end
          end
        end
      end
    end
  end
end

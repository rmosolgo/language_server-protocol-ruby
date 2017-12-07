require "socket"
require "language_server/protocol/transport/socket/reader"
require "language_server/protocol/transport/socket/writer"

module LanguageServer
  module Protocol
    module Transport
      module Socket
        # Handle the language server protocol over a TCP Socket.
        #
        # The server is blocking, but each client is
        # @example
        #   LSP::Transport::Socket.run_server(9009) do |message|
        #     # handle the incoming message
        #     handler = subscribers[message[:type]]
        #     response = handler.call(message)
        #     # return the response from the block
        #     response
        #   end
        #
        def self.run_server(port, &message_handler)
          server = TCPServer.new(port)
          loop do
            Thread.new(server.accept) do |client|
              writer = Transport::Socket::Writer.new(client)
              reader = Transport::Socket::Reader.new(client)
              reader.each_message do |message|
                response = message_handler.call(message)
                if response
                  writer.write(id: message[:id], result: response)
                end
              end
              # when each_message is done, the client hung up
              client.close
            end
          end
        end
      end
    end
  end
end

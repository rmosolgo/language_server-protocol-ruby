require "test_helper"
require "open3"

class LanguageServer::ProtocolTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::LanguageServer::Protocol::VERSION
  end

  def test_initialize_call
    stdin, stdout, stderr, wait_thr = *Open3.popen3("bundle exec ruby test/example.rb")

    stdin.print to_jsonrpc(jsonrpc: 2.0, id: 0, method: :initialize, params: {processId: 1234})

    sleep 1 unless wait_thr.stop?

    expected_body = {
      "id"=>0,
      "result"=>{"capabilities"=>{"textDocumentSync"=>{"change"=>1}, "completionProvider"=>{"resolveProvider"=>true, "triggerCharacters"=>["."]}, "definitionProvider"=>true}},
      "jsonrpc"=>"2.0"
    }

    assert{ stdout.read == to_jsonrpc(expected_body) }
    assert { stderr.read == "" }
  end

  def test_socket_initialize_call
    # Start the server, wait for it to boot
    server_process = fork do
      require_relative("../socket_example")
    end
    sleep 1

    # Connect to the server, send it an initialize message
    client = TCPSocket.new 'localhost', 1234
    client.print to_jsonrpc(jsonrpc: 2.0, id: 0, method: :initialize, params: {processId: 1234})
    sleep 1

    # Read the expected response, make sure it matches
    expected_body = {
      "id"=>0,
      "result"=>{"capabilities"=>{"textDocumentSync"=>{"change"=>1}, "completionProvider"=>{"resolveProvider"=>true, "triggerCharacters"=>["."]}, "definitionProvider"=>true}},
      "jsonrpc"=>"2.0"
    }
    expected_response = to_jsonrpc(expected_body)
    response = client.read(expected_response.bytesize)

    assert { response == expected_response }
  ensure
    # Make sure the server is stopped
    Process.kill("HUP", server_process)
  end

  def to_jsonrpc(hash)
    hash_str = hash.to_json

    "Content-Length: #{hash_str.bytesize}\r\n" + "\r\n" + hash_str
  end
end

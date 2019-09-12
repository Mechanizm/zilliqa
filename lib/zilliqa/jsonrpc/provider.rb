require 'jsonrpc-client'

module JSONRPC
  class Base
    def self.make_id
      "1"
    end
  end
end

module Zilliqa
  module Jsonrpc
    class Provider
      def initialize(endpoint)
        conn = Faraday.new { |connection|
          connection.adapter Faraday.default_adapter
        }
        @client = JSONRPC::Client.new(endpoint, { connection: conn })
        @endpoint = endpoint
      end

      def method_missing(sym, *args)
        @client.invoke(sym.to_s, args)
      end

      def testnet?
        @endpoint && !@endpoint.match('dev').nil?
      end
    end
  end
end
require 'jsonrpc-client'
require 'zilliqa/util/bech32'

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

      def GetBalance(*args)
        formatted = args.map { |addr| Util::Bech32.to_checksum_address(addr).downcase.sub('0x', '') }
        @client.invoke('GetBalance', formatted)
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

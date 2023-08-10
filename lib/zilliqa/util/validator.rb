module Zilliqa
  module Util
    class Validator
      def self.public_key?(public_key)
        m = /(0x)?\h{66}/ =~ public_key
        m != nil
      end

      def self.private_key?(private_key)
        m = /(0x)?\h{64}/ =~ private_key
        m != nil
      end

      def self.address?(address)
        return true if bech32?(address)
        m = /(0x)?\h{40}/ =~ address
        m != nil
      end

      def self.signature?(signature)
        m = /(0x)?\h{128}/ =~ signature
        m != nil
      end

      def self.bech32?(address)
        m = /^zil1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]{38}/ =~ address
        m != nil
      end
    end
  end
end

require 'bitcoin'

module Zilliqa
  module Util
    class Bech32

      def self.to_bech32(address)
        raise 'Invalid address format.' unless Validator.address?(address)

        address = address.sub('0x','')

        ret = Bitcoin::Bech32.convert_bits(Util.decode_hex(address).bytes, from_bits: 8, to_bits: 5, pad: false)

        Bitcoin::Bech32.encode('zil', ret)
      end

      def self.from_bech32(address)
        data = Bitcoin::Bech32.decode(address)

        raise 'Expected hrp to be zil' unless data[0] == 'zil'

        ret = Bitcoin::Bech32.convert_bits(data[1], from_bits: 5, to_bits: 8, pad: false)

        to_checksum_address(Util.encode_hex(ret.pack('c*'))).sub('0x', '')
      end

      # to_checksum_address
      #
      # takes hex-encoded string and returns the corresponding address
      #
      # @param {string} address
      # @returns {string}
      def self.to_checksum_address(address)
        return from_bech32(address) if Validator.bech32?(address)

        address = address.downcase.gsub('0x', '')
        s1 = Digest::SHA256.hexdigest(Util.decode_hex(address))
        v = s1.to_i(16)

        ret = ['0x']
        address.each_char.each_with_index do |c, idx|
          if '1234567890'.include?(c)
            ret << c
          else
            ret << ((v & (2 ** (255 - 6 * idx))) < 1 ? c.downcase : c.upcase)
          end
        end

        ret.join
      end
    end
  end
end

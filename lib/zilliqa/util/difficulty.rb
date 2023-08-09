module Zilliqa
  module Util
    class Difficulty
      ZERO_MASK = [0xFF, 0x7F, 0x3F, 0x1F, 0x0F, 0x07, 0x03, 0x01]
      DIVIDEND = 'ffff000000000000000000000000000000000000000000000000000000000000'

      def self.to_boundary_divided(difficulty)
        n_divided = 8
        n_divided_start = 32

        return to_boundary(difficulty) if difficulty < n_divided_start

        n_level = (difficulty - n_divided_start) / n_divided
        m_sub_level = (difficulty - n_divided_start) % n_divided
        difficulty_level = n_divided_start + n_level

        int_boundary = to_boundary(difficulty_level)

        boundary_change_step = (int_boundary >> 1).div(n_divided)

        int_boundary - (boundary_change_step * m_sub_level)
      end

      def self.to_boundary(difficulty)
        boundary = ['ff'*32].pack('H*').bytes

        n_bytes_to_zero = difficulty / 8
        n_bits_to_zero = difficulty % 8

        (0..n_bytes_to_zero).each { |i| boundary[i] = 0 }

        boundary[n_bytes_to_zero] = ZERO_MASK[n_bits_to_zero]

        boundary.pack('C*').unpack('H*').first.to_i(16)
      end


      def self.to_hashpower_divided(difficulty)
        boundary = to_boundary_divided(difficulty)

        int_dividend = DIVIDEND.to_i(16)
        int_dividend / boundary
      end
    end
  end
end

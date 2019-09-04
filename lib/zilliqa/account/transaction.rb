# frozen_string_literal: true

module Zilliqa
  module Account
    #
    # Transaction
    #
    # Transaction is a functor. Its purpose is to encode the possible states a
    # Transaction can be in:  Confirmed, Rejected, Pending, or Initialised (i.e., not broadcasted).
    class Transaction
      ATTRIBUTES = %i[id version nonce amount gas_price gas_limit signature receipt sender_pub_key to_addr code data to_ds].freeze
      attr_accessor(*ATTRIBUTES)
      attr_accessor :provider, :status

      GET_TX_ATTEMPTS = 33

      def initialize(tx_params, provider, status = TxStatus::INITIALIZED, to_ds = false)
        unless tx_params.nil?
          tx_params.each do |key, value|
            next unless ATTRIBUTES.include?(key)
            instance_variable_set("@#{key}", value)
          end
        end

        @provider = provider
        @status = status
        @to_ds = to_ds
      end

      # constructs an already-confirmed transaction.
      def self.confirm(tx_params, provider)
        Transaction.new(tx_params, provider, TxStatus::CONFIRMED)
      end

      # constructs an already-rejected transaction.
      def self.reject(tx_params, provider)
        Transaction.new(tx_params, provider, TxStatus::REJECTED)
      end

      def bytes
        protocol = Zilliqa::Proto::ProtoTransactionCoreInfo.new
        protocol.version = version.to_i
        protocol.nonce = nonce.to_i
        protocol.toaddr = Wallet.to_checksum_address(to_addr)
        protocol.toaddr = Util.decode_hex(to_addr.downcase.sub('0x', ''))
        protocol.senderpubkey = Zilliqa::Proto::ByteArray.new(data: Util.decode_hex(sender_pub_key))

        raise 'standard length exceeded for value' if amount.to_i > 2**128 - 1

        protocol.amount = Zilliqa::Proto::ByteArray.new(data: bigint_to_bytes(amount.to_i))
        protocol.gasprice = Zilliqa::Proto::ByteArray.new(data: bigint_to_bytes(gas_price.to_i))
        protocol.gaslimit = gas_limit.to_i
        protocol.code = code if code
        protocol.data = data if data

        Zilliqa::Proto::ProtoTransactionCoreInfo.encode(protocol)
      end

      def to_payload
        {
          version: version.to_i,
          nonce: nonce.to_i,
          toAddr: Wallet.to_checksum_address(to_addr),
          amount: amount.to_s,
          pubKey: sender_pub_key,
          gasPrice: gas_price.to_s,
          gasLimit: gas_limit.to_i,
          code: code,
          data: data,
          signature: signature
        }
      end

      def pending?
        @status == TxStatus::PENDING
      end

      def initialised?
        @status == TxStatus::INITIALIZED
      end

      def confirmed?
        @status == TxStatus::CONFIRMED
      end

      def rejected?
        @status == TxStatus::REJECTED
      end

      # This sets the Transaction instance to a state
      # of pending. Calling this function kicks off a passive loop that polls the
      # lookup node for confirmation on the txHash.
      #
      # The polls are performed with a linear backoff:
      #
      # This is a low-level method that you should generally not have to use
      # directly.
      def confirm(tx_hash, max_attempts = GET_TX_ATTEMPTS, interval = 1)
        @status = TxStatus::PENDING
        1.upto(max_attempts) do
          return self if track_tx(tx_hash)

          sleep(interval)
        end

        self.status = TxStatus::REJECTED
        throw 'The transaction is still not confirmed after ${maxAttempts} attempts.'
      end

      def track_tx(tx_hash)
        puts "tracking transaction: #{tx_hash}"

        begin
          response = @provider.GetTransaction(tx_hash)
        rescue StandardError => e
          puts 'transaction not confirmed yet'
          puts e
        end

        if response['error']
          puts 'transaction not confirmed yet'
          return false
        end

        self.id = response['result']['ID']
        self.receipt = response['result']['receipt']
        receipt['cumulative_gas'] = response['result']['receipt']['cumulative_gas'].to_i

        if receipt && receipt['success']
          puts 'Transaction confirmed!'
          self.status = TxStatus::CONFIRMED
        else
          puts 'Transaction rejected!'
          self.status = TxStatus::REJECTED
        end

        true
      end

      def transfer
        provider.CreateTransaction(to_payload)
      end

      private

      def bigint_to_bytes(value)
        raise 'standard length exceeded for value' if value > 2**128 - 1

        # bs = [value / (2**64), value % (2**64)].pack('Q>*')
      end
    end

    class TxStatus
      INITIALIZED = 0
      PENDING = 1
      CONFIRMED = 2
      REJECTED = 3
    end
  end
end

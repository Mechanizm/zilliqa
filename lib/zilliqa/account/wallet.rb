require 'digest'

module Zilliqa
  module Account
    class Wallet
      # Takes an array of Account objects and instantiates a Wallet instance.
      def initialize(provider = nil, accounts = {})
        @provider = provider
        @accounts = accounts
        if accounts.length > 0
          @default_account = accounts[0]
        else
          @default_account = nil
        end
      end

      # Creates a new keypair with a randomly-generated private key. The new
      # account is accessible by address.
      def create
        private_key = Zilliqa::Crypto::KeyTool.generate_private_key
        account = Zilliqa::Account::Account.new(private_key)

        @accounts[account.address] = account

        @default_account = account unless @default_account

        account.address
      end

      # Adds an account to the wallet by private key.
      def add_by_private_key(private_key)
        account = Zilliqa::Account::Account.new(private_key)

        @accounts[account.address] = account

        @default_account = account unless @default_account

        account.address
      end


      # Adds an account by keystore
      def add_by_keystore(keystore, passphrase)
        account = Zilliqa::Account::Account.from_file(keystore, passphrase)

        @accounts[account.address] = account

        @default_account = account unless @default_account

        account.address
      end

      # Removes an account from the wallet and returns boolean to indicate
      # failure or success.

      def remove(address)
        if @accounts.has_key?(address)
          @accounts.delete(address)

          true
        else
          false
        end
      end

      # Sets the default account of the wallet.
      def set_default(address)
        @default_account = @accounts[address]
      end

      # to_checksum_address
      #
      # takes hex-encoded string and returns the corresponding address
      #
      # @param {string} address
      # @returns {string}
      def self.to_checksum_address(address)
        return Zilliqa::Util::Bech32.from_bech32(address) if Zilliqa::Util::Validator.bech32?(address)
        address = address.downcase.gsub('0x', '')

        s1 = Digest::SHA256.hexdigest(Util.decode_hex(address))
        v = s1.to_i(base=16)

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

      def transfer(to_addr, amount)
        gas_price = Integer(@provider.GetMinimumGasPrice)
        gas_limit = 1

        tx = sign(Zilliqa::Account::Transaction.new({
          version: 65537,
          amount: amount.to_s,
          to_addr: to_addr,
          gas_price: gas_price.to_s,
          gas_limit: gas_limit
        }, @provider))
        tx.submit!
      end

      # signs an unsigned transaction with the default account.
      def sign(tx)
        if tx.sender_pub_key
          # attempt to find the address
          address = Zilliqa::Crypto::KeyTool.get_address_from_public_key(tx.sender_pub_key)
          account = @accounts[address]
          raise 'Could not sign the transaction with address as it does not exist' unless account

          sign_with(tx, address)
        else
          raise 'This wallet has no default account.' unless @default_account

          sign_with(tx, @default_account.address)
        end
      end

      def sign_with(tx, address)
        account = @accounts[address]
        address = @provider.testnet? ? Zilliqa::Util::Bech32.from_bech32(account.address) : account.address

        raise 'The selected account does not exist on this Wallet instance.' unless account

        if tx.nonce.nil?
          result = @provider.GetBalance(address)
          tx.nonce = result['nonce'].to_i + 1
        end

        tx.sender_pub_key = account.public_key
        sig = account.sign_transaction(tx)
        tx.signature = sig.to_s
        tx
      end
    end
  end
end
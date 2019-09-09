module Zilliqa
  module Account
    class TransactionFactory
      attr_reader :provider, :signer

      def initialize(provider, signer)
        @provider = provider
        @signer = signer
      end

      def new(tx_params, to_ds = false)
        Transaction.new(tx_params, @provider, Zilliqa::Account::Transaction::TX_STATUSES[:initialized], to_ds)
      end
    end
  end
end

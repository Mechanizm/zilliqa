# frozen_string_literal: true

require 'test_helper'

class TransactionFactoryTest < Minitest::Test
  def test_create_a_fresh_tx
    provider = Zilliqa::Jsonrpc::Provider.new('https://mock.zilliqa.com')
    wallet = Zilliqa::Account::Wallet.new(provider)
    transaction_factory = Zilliqa::Account::TransactionFactory.new(provider, wallet)

    tx_params = {
      version: '0',
      amount: '0',
      gas_price: '1',
      gas_limit: '100',
      to_addr: '0x88888888888888888888'
    }

    tx = transaction_factory.new(tx_params)

    assert tx.initialised?
  end
end

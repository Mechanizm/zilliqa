require 'test_helper'

class WalletTest < Minitest::Test
  def test_create
    wallet = Zilliqa::Account::Wallet.new(nil, {})
    address = wallet.create
    assert address
    assert Zilliqa::Util::Validator.address?(address)
  end

  def test_add_by_private_key
    wallet = Zilliqa::Account::Wallet.new(nil, {})
    address = wallet.add_by_private_key('24180e6b0c3021aedb8f5a86f75276ee6fc7ff46e67e98e716728326102e91c9')
    assert address
    assert Zilliqa::Util::Validator.address?(address)
  end

  def test_add_by_key_store
    json = "{\"address\":\"B5C2CDD79C37209C3CB59E04B7C4062A8F5D5271\",\"crypto\":{\"cipher\":\"aes-128-ctr\",\"cipherparams\":{\"iv\":\"BB77D985DFF840E54EE52510DDF6FE38\"},\"ciphertext\":\"2064375F0A006F70381B180B4B25A139F18F19A40F24ACA9B30AC9E51488DFD4\",\"kdf\":\"pbkdf2\",\"kdfparams\":{\"n\":8192,\"c\":262144,\"r\":8,\"p\":1,\"dklen\":32,\"salt\":[119,19,15,64,53,-57,27,-111,36,105,-72,36,-59,5,-128,77,41,113,-78,-60,66,-102,-123,1,100,-45,-114,80,71,-16,-75,31]},\"mac\":\"8F00ED9E2C84C9387CBC70AE305DBE7B87F87CE106227C381E5EA928A265BB8F\"},\"id\":\"9b5e1a6d-54e1-43a2-8a10-49ab4e41b903\",\"version\":3}\n";
    wallet = Zilliqa::Account::Wallet.new(nil, {})
    address = wallet.add_by_keystore(json, "xiaohuo")
    assert address
    assert Zilliqa::Util::Validator.address?(address)
  end

  def test_sign
    private_key = "e19d05c5452598e24caad4a0d85a49146f7be089515c905ae6a19e8a578a6930"
    public_key = '0246e7178dc8253201101e18fd6f6eb9972451d121fc57aa2a06dd5c111e58dc6a'

    provider = Minitest::Mock.new
    wallet = Zilliqa::Account::Wallet.new(provider, {})
    wallet.add_by_private_key(private_key)

    tx_params = {
      version: '0',
      nonce: '0',
      sender_pub_key: public_key,
      amount: '340282366920938463463374607431768211455',
      gas_price: '100',
      gas_limit: '1000',
      to_addr: '2E3C9B415B19AE4035503A06192A0FAD76E04243',
      code: 'abc',
      data: 'def'
    }

    tx = Zilliqa::Account::Transaction.new(tx_params, nil)

    wallet.sign(tx)

    message = tx.bytes
    message_hex = Zilliqa::Util.encode_hex(message)

    r, s = tx.signature[0..63], tx.signature[64..-1]
    result = Zilliqa::Crypto::Schnorr.verify(message_hex, Zilliqa::Crypto::Signature.new(r, s), public_key)
    assert result
  end

  require_relative '../contract/test_abi.rb'
  require_relative '../contract/test_contract.rb'

  def test_invalid_signature
    private_key = Zilliqa::Crypto::KeyTool.generate_private_key
    public_key = Zilliqa::Crypto::KeyTool.get_public_key_from_private_key(private_key)
    address = Zilliqa::Crypto::KeyTool.get_address_from_private_key(private_key)
    response = {
      id: 1,
      jsonrpc: '2.0',
      result: {
        balance: 888,
        nonce: 1
      }
    }

    provider = Minitest::Mock.new
    wallet = Zilliqa::Account::Wallet.new(provider, {})
    account = Zilliqa::Account::Account.new(private_key)
    wallet.add_by_private_key(private_key)

    provider.expect('GetBalance', response, [address])

    100.times do |i|
      provider.expect('GetBalance', response, [address])

      tx_params = {
        sender_pub_key: public_key,
        amount: (10**12) * rand(1..10),
        gas_price: rand(10..15_000),
        gas_limit: '1',
        to_addr: '1234567890123456789012345678901234567890',
        code: TEST_CONTRACT.gsub('/\\', ''),
        data: JSON.generate(ABI)
      }

      tx = Zilliqa::Account::Transaction.new(tx_params, nil)
      sig = account.sign_transaction(tx)
      assert Zilliqa::Util::Validator.signature?(sig.to_s)
    end
  end
end

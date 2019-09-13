# Zilliqa - Zilliqa Blockchain Ruby Library

- [Zilliqa API doc](https://apidocs.zilliqa.com/)
- The project is still under development.



## Table of Contents

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 orderedList:0 -->

#### [Requirements](#requirement)
#### [Installation](#installation)
#### [Zilliqa KeyTool](#zilliqa-keytool)
#### [Transaction](#transaction-z)
#### [Wallet](#wallet-z)
- [Smart Contract](#contract)
    - [Create](#contract-create)
    - [Deploy](#contract-deploy)

<!-- /TOC -->



## <a name="requirement"></a>Requirement

- Ruby(2.5.3)



## <a name="installation"></a>Installation

Add this line to your application's Gemfile:

```ruby
gem 'zilliqa'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zilliqa



## <a name="zilliqa-keytool"></a>Zilliqa KeyTool

### Generate A new address
```ruby
private_key = Zilliqa::Crypto::KeyTool.generate_private_key
public_key = Zilliqa::Crypto::KeyTool.get_public_key_from_private_key(private_key)
address = Zilliqa::Crypto::KeyTool.get_address_from_private_key(private_key)
```

### Validate an address
```ruby
address = '2624B9EA4B1CD740630F6BF2FEA82AAC0067070B'
Zilliqa::Util::Validator.address?(address)
```

### Validate checksum address
```ruby
checksum_address = '0x4BAF5faDA8e5Db92C3d3242618c5B47133AE003C'
Zilliqa::Util::Validator.checksum_address?(checksum_address)
```


## <a name="transaction-z"></a>Transaction

```ruby
provider = Zilliqa::Jsonrpc::Provider.new('https://dev-api.zilliqa.com')
to_addr = 'zil1lpw9fc8p4tse55r85fa37gscnkxf6xq5ahe8uj'
pub_key = '032cfec301c57acc2a4b18f47247687a1ec51e61336a7d5936e455b7dab3ae712e'
testnet = 21_823_489

tx_params = {
  version: testnet,
  amount: '0',
  to_addr: to_addr,
  gas_price: '1000',
  gas_limit: 1,
  sender_pub_key: pub_key
}

wallet = Zilliqa::Account::Wallet.new(provider)
transaction = Zilliqa::Account::Transaction.new(tx_params, provider)

wallet.add_by_private_key(private_key)

tx = wallet.sign(transaction)
tx.submit!
```

## <a name="wallet-z"></a>Wallet

```ruby
provider = Zilliqa::Jsonrpc::Provider.new('https://dev-api.zilliqa.com')
wallet = Zilliqa::Account::Wallet.new(provider)
wallet.add_by_private_key(private_key)
wallet.transfer('zil1lpw9fc8p4tse55r85fa37gscnkxf6xq5ahe8uj', 10 ** 12)
```

```
Successfull output
{
"ContractAddress"=>"1e366b36e5a17dec83c46f19d8d6b43434bd1dbb",
 "Info"=>"Contract Creation txn, sent to shard",
 "TranID"=>"411c1108800ac85118fcd9a44568d208276dcbdd5287c99119c69167912f344a"
}
```

## <a name="contract"> </a>Smart Contract


### <a name="contract-create"> </a>Create Smart contract
```ruby
private_key = "e19d05c5452598..."
provider = Zilliqa::Jsonrpc::Provider.new('https://dev-api.zilliqa.com')
wallet = Zilliqa::Account::Wallet.new(provider)
address = wallet.add_by_private_key(private_key)

factory = Zilliqa::Contract::ContractFactory.new(provider, wallet)

contract = factory.new_contract(TEST_CONTRACT, [
  {
    vname: 'owner',
    type: 'ByStr20',
    value: '0x124567890124567890124567890124567890',
  },
],
ABI,
)
```

### <a name="contract-deploy"> </a>Deploy contract

##### [How to calculate gas limit for smart contract transaction](https://drive.google.com/file/d/1c0EJXELVe_MxhULPuJgwGvxFGenG7fmK/view?usp=sharing)

```ruby
gas_limit = TEST_CONTRACT.bytes.size + ABI.to_s.bytes.size
```

```ruby
gas_price = 10 ** 12 # 1 zil
testnet_ver = 21_823_489
pub_key = '032cfec301...'

deploy_params = Zilliqa::Contract::DeployParams.new(nil, testnet_ver, nil, gas_price, gas_limit, pub_key)
tx, deployed = contract.deploy(deploy_params)

assert tx.confirmed?
assert deployed.deployed?
assert_equal Zilliqa::Contract::CONTRACT_STATUSES[:deployed], deployed.status

assert /[A-F0-9]+/ =~ contract.address

# call a deployed contract
call_tx = deployed.call(
      'setHello',
      [
        { vname: 'msg', type: 'String', value: 'Hello World!' },
      ],
      {
        version: Zilliqa::Util.pack(8, 8),
        amount: 0,
        gasPrice: 1000,
        gasLimit: 1000
      })


receipt = call_tx.receipt
```

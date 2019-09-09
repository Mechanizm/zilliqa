# frozen_string_literal: true

require 'json'

module Zilliqa
  module Contract
    class Contract
      include Account

      NIL_ADDRESS = '0000000000000000000000000000000000000000'

      attr_reader :factory, :provider, :signer, :code, :abi, :init, :state, :address, :status

      def initialize(factory, code, abi, address, init, state)
        @factory = factory
        @provider = factory.provider
        @signer = factory.signer

        @code = code
        @abi = abi
        @init = init
        @state = state

        if address && !address.empty?
          @address = address
          @status = ContractStatus::DEPLOYED
        else
          @status = ContractStatus::INITIALISED
        end
      end

      def initialised?
        @status == ContractStatus::INITIALISED
      end

      def deployed?
        @status == ContractStatus::DEPLOYED
      end

      def rejected?
        @status == ContractStatus::REJECTED
      end

      def deploy(deploy_params, attempts = 33, interval = 1000, _to_ds = false)
        raise 'Cannot deploy without code or initialisation parameters.' if @code.nil? || @code == ''
        raise 'Cannot deploy without code or initialisation parameters.' if @init.nil? || @init.length.zero?

        tx_params = {
          id: deploy_params.id,
          version: deploy_params.version,
          nonce: deploy_params.nonce,
          sender_pub_key: deploy_params.sender_pub_key,
          gas_price: deploy_params.gas_price,
          gas_limit: deploy_params.gas_limit,
          to_addr: NIL_ADDRESS,
          amount: '0',
          code: @code.gsub('/\\', ''),
          data: @init.to_json.gsub('\\"', '"')
        }

        tx = Transaction.new(tx_params, @provider)

        tx = prepare_tx(tx, attempts, interval)

        if tx.rejected?
          @status = ContractStatus::REJECTED

          return [tx, self]
        end

        @status = ContractStatus::DEPLOYED
        @address = ContractFactory.get_address_for_contract(tx)

        [tx, self]
      end

      def call(transition, args, params, attempts = 33, interval = 1000, to_ds = false)
        data = {
          _tag: transition,
          params: args
        }

        return 'Contract has not been deployed!' unless @address

        tx_params = {
          id: params['id'],
          version: params['version'],
          nonce: params['nonce'],
          sender_pub_key: params['sender_pub_key'],
          gas_price: params['gas_price'],
          gas_limit: params['gas_limit'],
          to_addr: @address,
          data: JSON.generate(data)
        }

        tx = Transaction.new(tx_params, @provider, Zilliqa::Account::Transaction::TX_STATUSES[:initialized], to_ds)

        prepare_tx(tx, attempts, interval)
      end

      def state
        return [] unless deployed

        response = @provider.GetSmartContractState(@address)
        response.result
      end

      def prepare_tx(tx, attempts, interval)
        tx = @signer.sign(tx)

        response = @provider.CreateTransaction(tx.to_payload)

        if response['error']
          tx.status = Zilliqa::Account::Transaction::TX_STATUSES[:rejected]
        else
          tx.confirm(response['result']['TranID'], attempts, interval)
        end

        tx
      end
    end

    class ContractStatus
      DEPLOYED = 0
      REJECTED = 1
      INITIALISED = 2
    end

    class Value
      attr_reader :vname, :type, :value
      def initialize(vname, type, value)
        @vname = vname
        @type = type
        @value = value
      end
    end

    class DeployParams
      attr_reader :id, :version, :nonce, :gas_price, :gas_limit, :sender_pub_key
      def initialize(id, version, nonce, gas_price, gas_limit, sender_pub_key)
        @id = id
        @version = version
        @nonce = nonce
        @gas_price = gas_price
        @gas_limit = gas_limit
        @sender_pub_key = sender_pub_key
      end
    end
  end
end

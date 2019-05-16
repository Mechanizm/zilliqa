# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: message.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("message.proto", :syntax => :proto2) do
    add_message "laksa.proto.ByteArray" do
      required :data, :bytes, 1
    end
    add_message "laksa.proto.ProtoTransactionCoreInfo" do
      optional :version, :uint32, 1
      optional :nonce, :uint64, 2
      optional :toaddr, :bytes, 3
      optional :senderpubkey, :message, 4, "laksa.proto.ByteArray"
      optional :amount, :message, 5, "laksa.proto.ByteArray"
      optional :gasprice, :message, 6, "laksa.proto.ByteArray"
      optional :gaslimit, :uint64, 7
      optional :code, :bytes, 8
      optional :data, :bytes, 9
    end
    add_message "laksa.proto.ProtoTransaction" do
      optional :tranid, :bytes, 1
      optional :info, :message, 2, "laksa.proto.ProtoTransactionCoreInfo"
      optional :signature, :message, 3, "laksa.proto.ByteArray"
    end
    add_message "laksa.proto.ProtoTransactionReceipt" do
      optional :receipt, :bytes, 1
      optional :cumgas, :uint64, 2
    end
    add_message "laksa.proto.ProtoTransactionWithReceipt" do
      optional :transaction, :message, 1, "laksa.proto.ProtoTransaction"
      optional :receipt, :message, 2, "laksa.proto.ProtoTransactionReceipt"
    end
  end
end

module Laksa
  module Proto
    ByteArray = Google::Protobuf::DescriptorPool.generated_pool.lookup("laksa.proto.ByteArray").msgclass
    ProtoTransactionCoreInfo = Google::Protobuf::DescriptorPool.generated_pool.lookup("laksa.proto.ProtoTransactionCoreInfo").msgclass
    ProtoTransaction = Google::Protobuf::DescriptorPool.generated_pool.lookup("laksa.proto.ProtoTransaction").msgclass
    ProtoTransactionReceipt = Google::Protobuf::DescriptorPool.generated_pool.lookup("laksa.proto.ProtoTransactionReceipt").msgclass
    ProtoTransactionWithReceipt = Google::Protobuf::DescriptorPool.generated_pool.lookup("laksa.proto.ProtoTransactionWithReceipt").msgclass
  end
end

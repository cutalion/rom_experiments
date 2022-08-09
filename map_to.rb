require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'logger'
require 'pry'

config = ROM::Configuration.new(:sql, 'sqlite::memory')

conn = config.gateways[:default].connection
config.gateways[:default].use_logger(Logger.new($stdout))

conn.create_table(:users) do
  primary_key :id
  column :name, String
end

conn.create_table(:addresses) do
  foreign_key :user_id, :users, null: false
  column :street, String
end

module Entities
end

class Entities::User < ROM::Struct
  def main_address
    addresses.first
  end
end

config.relation(:users) do
  auto_struct false

  schema(:users, infer: true) do
    associations do
      has_many :addresses
    end
  end
end

config.relation(:addresses) do
  auto_struct false

  schema(:addresses, infer: true) do
    associations do
      belongs_to :user
    end
  end
end

rom = ROM.container(config)

users = rom.relations[:users]
addresses = rom.relations[:addresses]

alex = users.changeset(:create, name: 'Alex').commit
address1 = addresses.changeset(:create, street: 'Street 1', user_id: alex[:id]).commit
address2 = addresses.changeset(:create, street: 'Street 2', user_id: alex[:id]).commit

class User
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
  end

  def [](name)
    attributes[name]
  end
end

puts users.combine(:addresses).map_to(User).first

binding.pry
1

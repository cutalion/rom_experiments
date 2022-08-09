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

class User
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
  end

  def [](name)
    attributes[name]
  end
end

class Address
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
  end

  def [](name)
    attributes[name]
  end
end

class Relation < ROM::Relation[:sql]
end

class Users < Relation
  schema(:users, infer: true) do
    associations do
      has_many :addresses
    end
  end

  def self.new(dataset = nil, **opts)
    opts[:meta] ||= {}
    opts[:meta][:model] ||= User
    super
  end
end

class Addresses < Relation
  schema(:addresses, infer: true) do
    associations do
      belongs_to :user
    end
  end

  def self.new(dataset = nil, **opts)
    opts[:meta] ||= {}
    opts[:meta][:model] ||= Address
    super
  end
end

config.register_relation(Users)
config.register_relation(Addresses)

rom = ROM.container(config)

users = rom.relations[:users]
addresses = rom.relations[:addresses]

alex = users.changeset(:create, name: 'Alex').commit
address1 = addresses.changeset(:create, street: 'Street 1', user_id: alex[:id]).commit
address2 = addresses.changeset(:create, street: 'Street 2', user_id: alex[:id]).commit

puts users.combine(:addresses).first

binding.pry
1

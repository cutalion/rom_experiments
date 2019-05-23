require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'logger'
require 'pry'
require 'securerandom'

config = ROM::Configuration.new(:sql, 'sqlite::memory')

conn = config.gateways[:default].connection
config.gateways[:default].use_logger(Logger.new($stdout))

conn.create_table(:users) do
  primary_key :id
  column :name, String, null: false
  column :is_admin, TrueClass, null: false, default: false
  column :secret, String, null: false
end

config.relation(:users) do
  schema(:users, infer: true)
end

class Users < ROM::Repository[:users]
  def create(params)
    secret = SecureRandom.hex
    root.changeset(:create, params.merge(secret: secret)).commit
  end
end

class Admins < ROM::Repository[:users]
  def create(params)
    secret = SecureRandom.hex
    root.changeset(:create, params.merge(secret: secret, is_admin: true)).commit
  end
end

rom = ROM.container(config)

users = Users.new(rom)
admins = Admins.new(rom)

alex = users.create name: 'Alex'
nikita = admins.create name: 'Nikita'

pp users.root.to_a

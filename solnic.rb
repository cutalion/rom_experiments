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
  column :account_type, String
  column :account_id, Integer
end

conn.create_table(:sitters) do
  primary_key :id
  column :name, String
end

conn.create_table(:sitter_profiles) do
  primary_key :id
  column :sitter_id, Integer
  column :about, String
end

config.relation(:users) do
  auto_struct true

  schema(:users, infer: true) do
    associations do
      belongs_to :sitter, foreign_key: :account_id
      has_one    :sitter_profile, through: :sitters
    end
  end

  def sitters
    where(account_type: 'Sitter')
  end
end

config.relation(:sitters) do
  auto_struct true

  schema(:sitters, infer: true) do
    associations do
      has_one :sitter_profile, as: :profile
      has_one :user, foreign_key: :account_id, view: :sitters
    end
  end
end

config.relation(:sitter_profiles) do
  auto_struct true

  schema(:sitter_profiles, infer: true) do
    associations do
      belongs_to :sitter
      has_one :user, through: :sitters
    end
  end
end

class Users < ROM::Repository[:users]
  commands :create
end

class Sitters < ROM::Repository[:sitters]
  commands :create
end

class SitterProfiles < ROM::Repository[:sitter_profiles]
  commands :create
end

rom = ROM.container(config)

users = rom.relations[:users]
sitters = rom.relations[:sitters]
profiles = rom.relations[:sitter_profiles]

user_repo = Users.new(rom)
sitter_repo = Sitters.new(rom)
profile_repo = SitterProfiles.new(rom)

sitter = sitters.command(:create).call(name: "Jane")
profile = profiles.command(:create).call(sitter_id: sitter.id, about: 'About Bob')
user = users.command(:create).call(name: 'Bob', account_id: sitter.id, account_type: 'Sitter')
user = users.command(:create).call(name: 'Alex', account_id: sitter.id, account_type: 'NotSitter')

# combine does not work
profiles.combine(:user)

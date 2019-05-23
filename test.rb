require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'pry'

config = ROM::Configuration.new(:sql, 'sqlite::memory')
conn = config.gateways[:default].connection

conn.create_table(:users) do
  primary_key :id
  column :name, String
  column :updated_at, DateTime
  column :created_at, DateTime
end

conn.create_table(:tasks) do
  primary_key :id
  column :user_id, Integer
  column :title, String
  column :status, String
end

config.relation(:users) do
  schema(:users, infer: true) do
    associations do
      has_many :tasks
    end
  end
end

config.relation(:tasks) do
  schema(:tasks, infer: true) do
    associations do
      belongs_to :user
    end
  end
end

rom = ROM.container(config)
users = rom.relations[:users]
tasks = rom.relations[:tasks]

user = users.changeset(:create, name: 'Alex').map(:add_timestamps).commit

tasks.changeset(:create, user_id: user[:id], title: 'Task 1', status: 'active').commit
tasks.changeset(:create, user_id: user[:id], title: 'Task 2', status: 'pending').commit
tasks.changeset(:create, user_id: user[:id], title: 'Task 3', status: 'pending').commit

puts 'REL'
puts users.join(tasks) { |users:, tasks:| tasks[:user_id].is(users[:id]) & tasks[:status].is('active') }

puts 'ASSOC'
puts users.join(:tasks) { |users:, tasks:| tasks[:user_id].is(users[:id]) & tasks[:status].is('active') }

binding.pry

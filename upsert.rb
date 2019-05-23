require 'pry'
require 'rom'
require 'rom-sql'

config = ROM::Configuration.new(:sql, 'postgres://localhost/rom_experiments')
conn = config.gateways[:default].connection

conn.drop_table?(:tasks)

conn.create_table(:tasks) do
  primary_key :id
  column :a, Integer
  column :b, Integer
  column :status, String

  index [:a, :b], unique: true
end

config.relation(:tasks) do
  schema(:tasks, infer: true)
end

rom = ROM.container(config)
tasks = rom.relations.tasks

puts tasks.to_a.inspect

params = { a: 1, b: 1, status: 'pending'}
tasks.upsert(params, target: [:a, :b], update: params)
puts tasks.to_a.inspect

params = { a: 1, b: 2, status: 'active'}
tasks.upsert(params, target: [:a, :b], update: params)
puts tasks.to_a.inspect

tasks.upsert(params, target: [:a, :b], update: params)
puts tasks.to_a.inspect

binding.pry

1 == 1

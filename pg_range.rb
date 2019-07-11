require 'rom'
require 'rom-sql'
require 'pry'

config = ROM::Configuration.new(:sql, 'postgres://localhost/rom_experiments')
conn = config.gateways[:default].connection

conn.drop_table?(:pg_ranges)

conn.create_table(:pg_ranges) do
  primary_key :id
  tstzrange :range
end

config.relation(:pg_ranges) do
  schema(:pg_ranges, infer: true) do
    attribute :range, ROM::SQL::Types::PG::TsTzRange
  end
end

rom = ROM.container(config)
pg_ranges = rom.relations.pg_ranges

record = pg_ranges.changeset(:create, range: Time.now..(Time.now + 10)).commit

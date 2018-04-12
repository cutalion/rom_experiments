require 'rom'
require 'rom-sql'
require 'pry'

config = ROM::Configuration.new(:sql, 'postgres://localhost/rom_experiments')
conn = config.gateways[:default].connection

conn.drop_table?(:pg_ranges)

conn.create_table(:pg_ranges) do
  primary_key :id
  daterange :range
end

config.relation(:pg_ranges) do
  schema(:pg_ranges, infer: true)
end

rom = ROM.container(config)
pg_ranges = rom.relations.pg_ranges

record = pg_ranges.changeset(:create, range: ROM::SQL::Postgres::Values::Range.new(Date.today, Date.today + 10, :'[]')).commit
puts pg_ranges.where(range: record[:range]).to_a.inspect # works
puts Hash[pg_ranges.where(range: record[:range]).one].inspect # works
puts pg_ranges.where { range.overlap(record[:range]) }.to_a.inspect # does not work

# rom.relations.pg_ranges.changeset(:create, range: Date.today..(Date.today + 10)).commit

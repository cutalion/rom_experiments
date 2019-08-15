require 'rom'
require 'rom-sql'
require 'pry'

class CustomRange < Range
  def exclude_begin?
    false
  end

  def lower
    self.begin
  end

  def upper
    self.end
  end
end

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

ruby_range = Range.new(Time.now, Time.now)
rom_range = ROM::SQL::Postgres::Values::Range.new(Time.now, Time.now)
sequel_range = Sequel::Postgres::PGRange.new(Time.now, Time.now)
custom_range = CustomRange.new(Time.now, Time.now)

def try(name)
  yield
  puts "#{name} works"
  rescue => e
    puts "#{name} does not work"
    puts e.message
  ensure
    puts
end

try(:ruby_range) { pg_ranges.changeset(:create, range: ruby_range).commit }
try(:sequel_range) { pg_ranges.changeset(:create, range: sequel_range).commit }
try(:rom_range) { pg_ranges.changeset(:create, range: rom_range).commit }
try(:custom_range) { pg_ranges.changeset(:create, range: custom_range).commit }

require 'rom'
require 'rom-sql'

config = ROM::Configuration.new(:sql, 'sqlite::memory')
conn = config.gateways[:default].connection

conn.create_table(:tasks) do
  primary_key :id
  column :status, String
end

config.relation(:tasks) do
  schema(:tasks, infer: true)

  def active
    where do
      ::Kernel.puts "REL: #{schema.relations.inspect}";
      schema.relations[:tasks][:status] == 'active'
    end
  end
end

rom = ROM.container(config)
rom.relations.tasks.active #=> NoMethodError: undefined method `tasks' for {}:Hash

require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'logger'
require 'pry'

gateways = {
  default: [:sql, 'sqlite::memory'],
  memory: [:memory]
}
rom = ROM.container(gateways) do |config|
  # config.gateways[:default].use_logger(Logger.new($stdout))
  # config.gateways[:memory].use_logger(Logger.new($stdout))

  sql = config.gateways[:default].connection

  sql.create_table(:companies) do
    primary_key :id
    column :name, String
    column :symbol, String
  end

  config.relation(:companies) do
    schema(:companies, infer: true) do
      associations do
        belongs_to :market_data, foreign_key: :symbol, view: :capitalization, override: true
      end
    end
  end

  config.relation(:market_data, adapter: :memory) do
    # do we need schema?
    schema do
      attribute :symbol, ROM::Types::String
      attribute :cap, ROM::Types::String
    end

    def capitalization(_assoc, companies)
      MARKET.select do |company|
        companies.pluck(:symbol).include? company[:symbol]
      end
    end
  end
end

companies = rom.relations[:companies]
companies.changeset(:create, [{ name: 'Google', symbol: 'GOOG' }]).commit
companies.changeset(:create, [{ name: 'Facebook', symbol: 'FB' }]).commit
companies.changeset(:create, [{ name: 'Apple', symbol: 'AAPL' }]).commit

# Our external source of market data
MARKET = [
  { symbol: 'FB',   cap: '518B' },
  { symbol: 'GOOG', cap: '754B' },
  { symbol: 'AAPL', cap: '895B' }
]

result = companies
         .where(symbol: ['FB', 'AAPL'])
         .combine(:market_data)

puts result

# Need to get
# {:id=>2, :name=>"Facebook", :symbol=>"FB", :cap=>"518B"}
# {:id=>3, :name=>"Apple", :symbol=>"AAPL", :cap=>"895B"}

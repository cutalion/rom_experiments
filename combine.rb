require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'logger'
require 'pry'

config = ROM::Configuration.new(:sql, 'sqlite::memory')

conn = config.gateways[:default].connection
config.gateways[:default].use_logger(Logger.new($stdout))

conn.create_table(:companies) do
  primary_key :id
  column :name, String
end

conn.create_table(:users) do
  primary_key :id
  column :company_id, Integer
  column :name, String
end

conn.create_table(:posts) do
  primary_key :id
  column :user_id, Integer
  column :body, String
end

conn.create_table(:comments) do
  primary_key :id
  column :user_id, Integer
  column :post_id, Integer
  column :body, String
end

config.relation(:companies) do
  auto_struct true

  schema(:companies, infer: true) do
    associations do
      has_many :users
    end
  end
end

config.relation(:users) do
  auto_struct true

  schema(:users, infer: true) do
    associations do
      has_many :posts
      belongs_to :company
    end
  end
end

config.relation(:posts) do
  auto_struct true

  schema(:posts, infer: true) do
    associations do
      belongs_to :user
      has_many :comments
    end
  end
end

config.relation(:comments) do
  auto_struct true

  schema(:comments, infer: true) do
    associations do
      belongs_to :post
      belongs_to :user
      has_one :user, through: :posts, as: :post_author, foreign_key: :user_id
      has_one :company, through: :users, as: :post_author_company, foreign_key: :company_id
    end
  end
end

rom = ROM.container(config)

companies = rom.relations[:companies]
users = rom.relations[:users]
posts = rom.relations[:posts]
comments = rom.relations[:comments]

companies.changeset(:create, [{ name: 'Gogol' }]).commit
users.changeset(:create, [{ name: 'Alex', company_id: 1}, { name: 'Bob', company_id: 1 }]).commit
posts.changeset(:create, { body: 'Post', user_id: 1 }).commit
comments.changeset(:create, { body: 'Comment', user_id: 2 }).commit

# how did it get the post_author if comment does not have a post_id?
puts comments.combine(:post_author, :post_author_company).to_a.inspect

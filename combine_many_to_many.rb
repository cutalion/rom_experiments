require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'logger'
require 'pry'

config = ROM::Configuration.new(:sql, 'sqlite::memory')

conn = config.gateways[:default].connection
config.gateways[:default].use_logger(Logger.new($stdout))

conn.create_table(:posts) do
  primary_key :id
  column :title, String
  column :tag_id, Integer
end

conn.create_table(:posts_tags) do
  column :post_id, Integer
  column :tag_id, Integer
end

conn.create_table(:tags) do
  primary_key :id
  column :name, String
end

config.relation(:posts) do
  schema(:posts, infer: true) do
    associations do
      has_many :posts_tags
      has_many :tags, through: :posts_tags
    end
  end
end

config.relation(:posts_tags) do
  schema(:posts_tags, infer: true) do
    associations do
      belongs_to :post
      belongs_to :tag
    end
  end
end

config.relation(:tags) do
  schema(:tags, infer: true) do
    associations do
      has_many :posts_tags
      has_many :posts, through: :posts_tags
    end
  end
end

rom = ROM.container(config)

posts      = rom.relations[:posts]
posts_tags = rom.relations[:posts_tags]
tags       = rom.relations[:tags]

js = tags.changeset(:create, { name: 'JS' }).commit
ruby = tags.changeset(:create, { name: 'RUBY' }).commit

foo = posts.changeset(:create, { title: 'FOO' }).commit
bar = posts.changeset(:create, { title: 'BAR' }).commit

posts_tags.changeset(:create, [
  { post_id: foo[:id], tag_id: js[:id] },
  { post_id: foo[:id], tag_id: ruby[:id] },
  { post_id: bar[:id], tag_id: ruby[:id] }
]).commit

pp tags.combine(:posts).to_a

binding.pry
1


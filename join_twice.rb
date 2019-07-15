require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'pry'

config = ROM::Configuration.new(:sql, 'sqlite::memory')
conn = config.gateways[:default].connection

conn.create_table(:users) do
  primary_key :id
  column :name, String
end

conn.create_table(:tasks) do
  primary_key :id
  column :user_id, Integer
  column :title, String
  column :status, String
  column :severity, String
end

conn.create_table(:posts) do
  primary_key :id
  column :user_id, Integer
  column :title, String
  column :body, String
end

config.relation(:users) do
  schema(:users, infer: true) do
    associations do
      has_many :tasks
      has_many :posts
    end
  end
end

config.relation(:tasks) do
  schema(:tasks, infer: true)
end

config.relation(:posts) do
  schema(:posts, infer: true)
end

rom = ROM.container(config)

users = rom.relations[:users]
tasks = rom.relations[:tasks]
posts = rom.relations[:posts]

# builds possibly wrong join (JOIN posts ON posts.user_id = tasks.id)
puts users
  .join(:tasks, user_id: :id)
  .join(:posts, user_id: :id)
  .dataset
  .sql

# requires defined associations
puts users
  .join(tasks, user_id: :id)
  .join(posts, user_id: :id)
  .dataset
  .sql

__END__

SELECT `users`.`id`,
       `users`.`name`
FROM `users`
INNER JOIN `tasks` ON (`tasks`.`user_id` = `users`.`id`)
INNER JOIN `posts` ON (`posts`.`user_id` = `tasks`.`id`)
ORDER BY `users`.`id`


SELECT `users`.`id`,
       `users`.`name`
FROM `users`
INNER JOIN `tasks` ON (`users`.`id` = `tasks`.`user_id`)
INNER JOIN `posts` ON (`users`.`id` = `posts`.`user_id`)
ORDER BY `users`.`id`

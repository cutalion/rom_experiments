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

config.relation(:users) do
  schema(:users, infer: true) do
    associations do
      has_many :tasks
    end
  end

  def with_active_tasks
    join(:tasks).where(status: 'active')
  end

  def with_critical_tasks
    join(:tasks).where(severity: 'critical')
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

alex = users.changeset(:create, name: 'Alex').commit
john = users.changeset(:create, name: 'John').commit

tasks.changeset(:create, user_id: alex[:id], title: 'Task 1', status: 'active', severity: 'critical').commit
tasks.changeset(:create, user_id: alex[:id], title: 'Task 2', status: 'pending', severity: 'critical').commit
tasks.changeset(:create, user_id: alex[:id], title: 'Task 3', status: 'pending', severity: 'normal').commit

tasks.changeset(:create, user_id: john[:id], title: 'Task 4', status: 'active', severity: 'normal').commit
tasks.changeset(:create, user_id: john[:id], title: 'Task 5', status: 'pending', severity: 'normal').commit
tasks.changeset(:create, user_id: john[:id], title: 'Task 6', status: 'pending', severity: 'normal').commit

def search(users, params)
  result = users
  result = result.with_critical_tasks if params[:critical]
  result = result.with_active_tasks if params[:active]
  puts result.distinct.dataset.sql
  result.distinct.to_a
end

puts 'With critical tasks:'
pp search(users, critical: true)
puts

puts 'With active tasks:'
pp search(users, active: true)
puts

puts 'With active critical tasks:'
pp search(users, critical: true, active: true)

__END__

$ ruby join.rb
With critical tasks:
SELECT DISTINCT `users`.`id`, `users`.`name` FROM `users` INNER JOIN `tasks` ON (`users`.`id` = `tasks`.`user_id`) WHERE (`severity` = 'critical') ORDER BY `users`.`id`
[{:id=>1, :name=>"Alex"}]

With active tasks:
SELECT DISTINCT `users`.`id`, `users`.`name` FROM `users` INNER JOIN `tasks` ON (`users`.`id` = `tasks`.`user_id`) WHERE (`status` = 'active') ORDER BY `users`.`id`
[{:id=>1, :name=>"Alex"}, {:id=>2, :name=>"John"}]

With active critical tasks:
SELECT DISTINCT `users`.`id`, `users`.`name` FROM `users` INNER JOIN `tasks` ON (`users`.`id` = `tasks`.`user_id`) INNER JOIN `tasks` ON (`users`.`id` = `tasks`.`user_id`) WHERE ((`severity` = 'critical') AND (`status` = 'active')) ORDER BY `users`.`id`
Traceback (most recent call last):
        21: from join.rb:78:in `<main>'
        20: from join.rb:66:in `search'
        19: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/rom-core-5.0.2/lib/rom/relation.rb:363:in `to_a'
        18: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/rom-core-5.0.2/lib/rom/relation.rb:363:in `to_a'
        17: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/rom-core-5.0.2/lib/rom/relation.rb:363:in `each'
        16: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/rom-core-5.0.2/lib/rom/relation.rb:223:in `each'
        15: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/dataset/actions.rb:443:in `map'
        14: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/dataset/actions.rb:443:in `map'
        13: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/dataset/actions.rb:152:in `each'
        12: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/adapters/sqlite.rb:327:in `fetch_rows'
        11: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/dataset/actions.rb:1088:in `execute'
        10: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/adapters/sqlite.rb:139:in `execute'
         9: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/adapters/sqlite.rb:193:in `_execute'
         8: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/database/connecting.rb:270:in `synchronize'
         7: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/connection_pool/threaded.rb:92:in `hold'
         6: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/adapters/sqlite.rb:200:in `block in _execute'
         5: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/database/logging.rb:38:in `log_connection_yield'
         4: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sequel-5.21.0/lib/sequel/adapters/sqlite.rb:200:in `block (2 levels) in _execute'
         3: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sqlite3-1.4.1/lib/sqlite3/database.rb:336:in `query'
         2: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sqlite3-1.4.1/lib/sqlite3/database.rb:147:in `prepare'
         1: from /home/cutalion/.rvm/gems/ruby-2.5.1/gems/sqlite3-1.4.1/lib/sqlite3/database.rb:147:in `new'
/home/cutalion/.rvm/gems/ruby-2.5.1/gems/sqlite3-1.4.1/lib/sqlite3/database.rb:147:in `initialize': SQLite3::SQLException: ambiguous column name: severity (Sequel::DatabaseError)

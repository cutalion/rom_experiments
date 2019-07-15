require 'active_record'
require 'pry'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

connection = ActiveRecord::Base.connection

connection.create_table :users, force: true do |t|
  t.string :name
end

connection.create_table :tasks, force: true do |t|
  t.integer :user_id
  t.string :title
  t.string :status
  t.string :severity
end

class User < ActiveRecord::Base
  has_many :tasks

  scope :with_active_tasks, -> { joins(:tasks).where(tasks: { status: 'active' }) }
  scope :with_critical_tasks, -> { joins(:tasks).where(tasks: { severity: 'critical' }) }
end

class Task < ActiveRecord::Base
  belongs_to :user
end

alex = User.create(name: 'Alex')
john = User.create(name: 'John')

Task.create(
  [
    { user: alex, title: 'Task 1', status: 'active', severity: 'critical' },
    { user: alex, title: 'Task 2', status: 'pending', severity: 'critical' },
    { user: alex, title: 'Task 3', status: 'pending', severity: 'normal' },

    { user: john, title: 'Task 4', status: 'active', severity: 'normal' },
    { user: john, title: 'Task 5', status: 'pending', severity: 'normal' },
    { user: john, title: 'Task 6', status: 'pending', severity: 'normal' }
  ]
)

binding.pry
def search(users, params)
  result = users
  result = result.with_critical_tasks if params[:critical]
  result = result.with_active_tasks if params[:active]
  puts result.distinct.to_sql
  result.distinct.to_a
end

users = User.all

puts 'With critical tasks:'
pp search(users, critical: true)
puts

puts 'With active tasks:'
pp search(users, active: true)
puts

puts 'With active critical tasks:'
pp search(users, critical: true, active: true)

__END__

$ ruby join_ar.rb
With critical tasks:
SELECT DISTINCT "users".* FROM "users" INNER JOIN "tasks" ON "tasks"."user_id" = "users"."id" WHERE "tasks"."severity" = 'critical'
[#<User:0x00005636ab492c48 id: 1, name: "Alex">]

With active tasks:
SELECT DISTINCT "users".* FROM "users" INNER JOIN "tasks" ON "tasks"."user_id" = "users"."id" WHERE "tasks"."status" = 'active'
[#<User:0x00005636ab303418 id: 1, name: "Alex">,
 #<User:0x00005636ab303058 id: 2, name: "John">]

With active critical tasks:
SELECT DISTINCT "users".* FROM "users" INNER JOIN "tasks" ON "tasks"."user_id" = "users"."id" WHERE "tasks"."severity" = 'critical' AND "tasks"."status" = 'active'
[#<User:0x00005636ab2c07d0 id: 1, name: "Alex">]

require 'rom'
require 'rom-repository'
require 'rom-sql'
require 'pry'

module Entity
end

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
end

config.relation(:users) do
  schema(:users, infer: true) do
    associations do
      has_many :tasks
      has_one :tasks, as: :active_task, view: :active
    end
  end

  def with_tasks
    left_join(:active_task).select_append(:status)
  end
end

config.relation(:tasks) do
  schema(:tasks, infer: true) do
    associations do
      belongs_to :user
    end
  end

  def active
    where(status: 'active')
  end
end

class Users < ROM::Repository[:users]
  struct_namespace Entity
  commands :create
end

class Tasks < ROM::Repository[:tasks]
  struct_namespace Entity
  commands :create
end

rom = ROM.container(config)

user_repo = Users.new(rom)
task_repo = Tasks.new(rom)

user = user_repo.create(name: 'Alex')

task_repo.create(user_id: user.id, title: 'Task 1', status: 'active')
task_repo.create(user_id: user.id, title: 'Task 2', status: 'pending')
task_repo.create(user_id: user.id, title: 'Task 3', status: 'pending')

puts user_repo.aggregate(:active_task).one.inspect

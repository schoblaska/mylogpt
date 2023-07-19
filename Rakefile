require_relative "boot"

task :console do
  binding.pry
end

namespace :db do
  task :load do
    `cat data/dump.sql | docker-compose exec -T mylogpt_postgres bash -c 'PGPASSWORD=#{DBCONFIG["password"]} psql -U #{DBCONFIG["username"]} -d #{DBCONFIG["database"]}'`
  end
end

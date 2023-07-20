require "bundler/setup"
require "dotenv/load"

require "active_record"
require "httparty"
require "json"
require "neighbor"
require "pg"
require "pry"
require "rake"
require "openai"
require "sidekiq"
require "tzinfo"

require_relative "lib/gpt_client"
require_relative "lib/responder_job"
require_relative "lib/tweet"

DBCONFIG = YAML.safe_load(ERB.new(File.read("config/database.yml")).result)
ActiveRecord::Base.establish_connection(DBCONFIG)

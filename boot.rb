require "bundler/setup"
require "dotenv/load"

Bundler.require(:default)

require_relative "lib/gpt_client"
require_relative "lib/responder_job"
require_relative "lib/tweet"

DBCONFIG = YAML.safe_load(ERB.new(File.read("config/database.yml")).result)
ActiveRecord::Base.establish_connection(DBCONFIG)

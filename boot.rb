require "bundler/setup"
require "dotenv/load"
Bundler.require(:default)

require_relative "lib/prompt"
require_relative "lib/gpt_client"
require_relative "lib/responder_job"

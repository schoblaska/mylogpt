require "bundler"
require "dotenv/load"
require "json"
require "openai"
require "sidekiq"
require "sinatra"
require "timeout"
require "tzinfo"

require_relative "lib/prompt"
require_relative "lib/responder_job"

def allow?(params)
  if ENV["RACK_ENV"] == "production"
    ENV["SLACK_VERIFICATION_TOKEN"] == params[:token]
  else
    true
  end
end

post "/tweet" do
  content_type :json

  halt(403, "Invalid Request") unless allow?(params)

  ResponderJob.perform_async(params[:text], params[:response_url])

  { response_type: "in_channel", text: "..." }
rescue Timeout::Error
  halt(408, "Request Timeout")
end

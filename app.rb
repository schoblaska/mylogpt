require "bundler"
require "dotenv/load"
require "json"
require "openai"
require "sidekiq"
require "sinatra"
require "timeout"
require "tzinfo"

require_relative "lib/prompt"

def now
  TZInfo::Timezone
    .get("America/Chicago")
    .now
    .strftime("%b %-d, %Y at %-l:%M %p")
end

def allow?(params)
  if ENV["RACK_ENV"] == "production"
    ENV["SLACK_VERIFICATION_TOKEN"] == params[:token]
  else
    true
  end
end

def chat(client, messages)
  Timeout.timeout(10) do
    response =
      client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: messages,
          temperature: 0.5
        }
      )

    response.dig("choices", 0, "message", "content")
  end
end

def generate_tweet(phrase)
  client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])

  response = chat(client, PROMPT + [{ role: "user", content: phrase }])

  if response[0] =~ /[A-Z]/
    # the real mylo doesn't start sentences with a capital letter.
    # we got back a generic ChatGPT response. ask it to try harder.
    response =
      chat(
        client,
        PROMPT +
          [
            { role: "user", content: phrase },
            { role: "assistant", content: response },
            {
              role: "user",
              content:
                "Generate a new response that matches the examples instead of being generic. Remember not to start a sentence with a capital letter."
            },
            { role: "user", content: phrase }
          ]
      )
  end

  response
end

post "/tweet" do
  content_type :json

  p params

  halt(403, "Invalid Request") unless allow?(params)

  tweet = generate_tweet(params[:text])

  {
    response_type: "in_channel",
    blocks: [
      { type: "section", text: { type: "mrkdwn", text: tweet } },
      {
        type: "context",
        elements: [
          {
            type: "image",
            image_url: "https://schoblaska.org/assets/twitter.png",
            alt_text: "Twitter logo"
          },
          { type: "mrkdwn", text: "Twitter | #{now}" }
        ]
      }
    ]
  }.to_json
rescue Timeout::Error
  halt(408, "Request Timeout")
end

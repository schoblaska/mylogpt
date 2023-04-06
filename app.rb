require "sinatra"
require "json"
require "dotenv/load"
require "tzinfo"
require "openai"

require_relative "lib/prompt"

def now
  TZInfo::Timezone
    .get("America/Chicago")
    .now
    .strftime("%b %-d, %Y at %-l:%M %p")
end

def allow?(params)
  if ENV["SINATRA_ENV"] == "production"
    ENV["SLACK_VERIFICATION_TOKEN"] == params[:token]
  else
    true
  end
end

def generate_tweet(phrase)
  # "my tiktok on #{phrase} is blowing up again"

  client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])

  response =
    client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: PROMPT + [{ role: "user", content: phrase }],
        temperature: 0.7
      }
    )

  p response

  response.dig("choices", 0, "message", "content")
end

post "/tweet" do
  content_type :json

  halt(403, "Invalid Request") unless allow?(params)

  tweet = generate_tweet(params[:text])

  {
    blocks: [
      { type: "section", text: { type: "mrkdwn", text: tweet } },
      {
        type: "context",
        elements: [
          {
            type: "image",
            image_url:
              "https://abs.twimg.com/icons/apple-touch-icon-192x192.png",
            alt_text: "images"
          },
          { type: "mrkdwn", text: "Twitter | #{now}" }
        ]
      }
    ]
  }.to_json
end

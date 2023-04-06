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

def chat(client, messages)
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
            { role: "assistant", content: response },
            {
              role: "user",
              content:
                "Generate a new response for \"#{phrase}\" that matches the examples instead of being generic. Remember not to start a sentence with a capital letter."
            }
          ]
      )
  end

  response
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

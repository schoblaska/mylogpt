require "sinatra"
require "json"
require "dotenv/load"

def post_data(request)
  request.body.rewind
  JSON.parse(request.body.read)
rescue StandardError
  {}
end

def allow?(params)
  if ENV["SINATRA_ENV"] == "production"
    ENV["SLACK_VERIFICATION_TOKEN"] == params["token"]
  else
    true
  end
end

def get_tweet(phrase)
  "my tiktok on #{phrase} is blowing up again"
end

post "/tweet" do
  content_type :json

  data = post_data(request)

  halt(403, "Invalid Request") unless allow?(data)

  tweet = get_tweet(data["text"])

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
          { type: "mrkdwn", text: "Twitter | Today at 5:00 PM" }
        ]
      }
    ]
  }.to_json
end

require "sinatra"
require "json"

def allow?
  return true unless ENV["SINATRA_ENV"] == "production"
  ENV["SLACK_VERIFICATION_TOKEN"] == params[:token]
end

def get_tweet(phrase)
  "my tiktok on #{phrase} is blowing up again"
end

post "/tweet" do
  content_type :json

  halt(403, "Invalid Request") unless allow?

  tweet = get_tweet(params[:text])

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

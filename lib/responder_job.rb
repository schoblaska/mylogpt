class ResponderJob
  include Sidekiq::Worker

  def perform(prompt, response_url)
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])

    if prompt.split(" ").length > 3 || prompt.length > 25
      prompt =
        chat(
          [
            {
              role: "user",
              content:
                "Using three words or less, extract the key words from this phrase: \"#{prompt}\""
            }
          ]
        )

      prompt.downcase!.gsub!(/\.$/, "")
    end

    tweet = generate_tweet(prompt)

    HTTParty.post(
      response_url,
      body: tweet_block(tweet).to_json,
      headers: {
        "Content-Type" => "application/json"
      }
    )
  end

  private

  def tweet_block(tweet)
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
    }
  end

  def chat(messages)
    Timeout.timeout(30) do
      response =
        @client.chat(
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
    chat(PROMPT + [{ role: "user", content: phrase }])
  end

  def now
    TZInfo::Timezone
      .get("America/Chicago")
      .now
      .strftime("%b %-d, %Y at %-l:%M %p")
  end
end

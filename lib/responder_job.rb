class ResponderJob
  include Sidekiq::Worker

  def perform(prompt, response_url)
    @gpt_client = GPTClient.new

    prompt = prompt.downcase.gsub(%r{[^a-z'\s/]}, "").strip

    if bad_prompt?(prompt)
      prompt =
        @gpt_client.chat(
          "Using three words or less, extract the key words from this phrase: \"#{prompt}\""
        )

      prompt = prompt.downcase.gsub(/\.$/, "").gsub(%r{[^a-z'\s/]}, "")
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

  def bad_prompt?(prompt)
    prompt.split(" ").length > 3 || prompt.length > 25 ||
      prompt =~ /^(what|who|why|how|would)/
  end

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

  def generate_tweet(phrase)
    @gpt_client.chat(phrase, add_prompt: true)
  end

  def now
    TZInfo::Timezone
      .get("America/Chicago")
      .now
      .strftime("%b %-d, %Y at %-l:%M %p")
  end
end

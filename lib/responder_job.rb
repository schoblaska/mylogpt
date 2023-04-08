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
    tweet = generate_tweet(prompt) if bad_tweet?(tweet) # try again

    response =
      if bad_tweet?(tweet)
        text_block("i'll be honest... i got nothing for that one")
      else
        tweet_block(tweet)
      end

    HTTParty.post(
      response_url,
      body: response.to_json,
      headers: {
        "Content-Type" => "application/json"
      }
    )
  end

  private

  def bad_prompt?(prompt)
    too_many_words = prompt.split(" ").length > 4
    too_long = prompt.length > 25
    question =
      prompt =~
        /^(what|who|why|how|would|is|are|could|how|should|do|where|which)/

    too_many_words || too_long || question
  end

  def bad_tweet?(tweet)
    sorry = tweet[0, 20] =~ /sorry/i
    info = tweet =~ /(context|information)/i
    ai_model = tweet =~ /ai language model/i
    capital_sentences = tweet =~ /\. [A-Z]/

    (sorry && info) || (sorry && capital_sentences) || ai_model
  end

  def text_block(text)
    { response_type: "in_channel", text: text }
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

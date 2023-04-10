class ResponderJob
  include Sidekiq::Worker

  def perform(prompt, response_url)
    @gpt_client = GPTClient.new

    prompt = generate_prompt(prompt)

    tweet = generate_tweet(prompt)
    tweet = generate_tweet(prompt) if bad_tweet?(tweet) # try again

    response =
      if bad_tweet?(tweet)
        puts "bad tweet: \"#{tweet}\""
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
    too_long = prompt.length > 30
    question =
      prompt =~
        /^(what|who|why|how|would|is|are|could|how|should|do|where|which|if)/

    too_many_words || too_long || question
  end

  def bad_tweet?(tweet)
    sorry = tweet[0, 20] =~ /sorry/i
    im_sorry = tweet =~ /^I'm sorry/
    info = tweet =~ /(context|information)/i
    more_info = tweet =~ /more (context|information)/i
    ai_model = tweet =~ /ai language model/i
    capital_sentences = tweet =~ /\. [A-Z]/
    assist = tweet =~ /how can i assist/i

    (sorry && info) || more_info || im_sorry || capital_sentences || ai_model ||
      assist
  end

  def text_block(text)
    { response_type: "in_channel", text: text }
  end

  def tweet_block(tweet)
    {
      response_type: "in_channel",
      blocks: [
        { type: "section", text: { type: "plain_text", text: tweet } },
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

  def generate_prompt(prompt)
    prompt = prompt.downcase.gsub(%r{[^a-z0-9'\s/]}, "").strip

    if bad_prompt?(prompt)
      new_prompt =
        @gpt_client.chat(
          "Using four words or less, extract the key words from this phrase: \"#{prompt}\""
        )

      new_prompt = new_prompt.downcase.gsub(/\.$/, "").gsub(%r{[^a-z'\s/]}, "")

      if prompt != new_prompt
        puts "change prompt from \"#{prompt}\" to \"#{new_prompt}\""
      end

      new_prompt
    else
      prompt
    end
  end

  def now
    TZInfo::Timezone
      .get("America/Chicago")
      .now
      .strftime("%b %-d, %Y at %-l:%M %p")
  end
end

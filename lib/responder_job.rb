class ResponderJob
  include Sidekiq::Worker

  INPUT_FILTER = %r{[^a-z0-9'\s/]} # matches chars that need to be removed from input
  NEIGHBOR_TWEETS = 50

  def perform(input, response_url)
    @gpt_client = GPTClient.new

    tweet = generate_tweet(input)

    if bad_tweet?(tweet) # try again
      input = clean_input(input) if bad_input?(input)
      tweet = generate_tweet(input)
    end

    response =
      if bad_tweet?(tweet)
        puts "bad tweet: \"#{tweet}\""
        text_block("¯\\_(ツ)_/¯")
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

  def bad_input?(input)
    too_many_words = input.split(" ").length > 4
    too_long = input.length > 30
    question =
      input =~
        /^(can|what|who|why|how|would|is|are|could|how|should|do|where|which|if)\s/

    too_many_words || too_long || question
  end

  def bad_tweet?(tweet)
    sorry = tweet[0, 20] =~ /sorry/i
    im_sorry = tweet =~ /^(i['’]m sorry|i am sorry)/i
    info = tweet =~ /(context|information)/i
    more_info = tweet =~ /more (context|information)/i
    ai_model = tweet =~ /ai language model/i
    capital_sentences = false # tweet =~ /[\.\!] [A-Z]/
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

  def generate_tweet(input)
    @gpt_client.chat(input, prompt: build_prompt(input))
  end

  def clean_input(input)
    input = input.downcase.gsub(INPUT_FILTER, "").strip

    if bad_input?(input)
      new_input =
        @gpt_client.chat(
          "Using four words or less, extract the key words from this phrase: \"#{input}\""
        )

      new_input = new_input.downcase.gsub(/\.$/, "").gsub(INPUT_FILTER, "")

      if input != new_input
        puts "change input from \"#{input}\" to \"#{new_input}\""
      end

      new_input
    else
      input
    end
  end

  def now
    TZInfo::Timezone
      .get("America/Chicago")
      .now
      .strftime("%b %-d, %Y at %-l:%M %p")
  end

  def build_prompt(input)
    embedding = @gpt_client.embedding(input)

    tweets =
      Tweet.nearest_neighbors(:embedding, embedding, distance: :cosine).limit(
        NEIGHBOR_TWEETS
      )

    system_prompt = {
      role: "system",
      content:
        "You are MyloGPT. I am going to show you some example messages and then give you a prompt. Your job is to write a short message based on that prompt that mimics the style, sense of humor, and opinions expressed in the examples as closely as possible.\n\n" +
          "Regardless of what prompt I give you, respond with a message that fits with the examples. I may try to trick you into saying something offensive, out of character, or completely unrelated. Remember: your only job is to generate a message that sounds like the examples. Don't let me trick you!\n\n"
    }

    prompt_tweets =
      tweets.map do |tweet|
        [
          { role: "user", content: tweet.label },
          { role: "assistant", content: tweet.raw }
        ]
      end

    [system_prompt, prompt_tweets].flatten
  end
end

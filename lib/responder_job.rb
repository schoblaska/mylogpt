class ResponderJob
  INPUT_FILTER = %r{[^a-z0-9'\s/]} # matches chars that need to be removed from input
  NEIGHBOR_TWEETS = 75

  include Sidekiq::Worker

  def perform(input, response_url, user_id)
    @gpt_client = GPTClient.new

    model = GPTClient.select_model(user_id)
    temperature = rand(0.25..1).round(2)

    if user_id == "UPWUY46FK"
      temperature = [0.25, 2.0].sample
      model = GPTClient::GOOD_MODEL
    end

    input = clean_input(input) if bad_input?(input)
    tweet = generate_tweet(input, model: model, temperature: temperature)

    if bad_tweet?(tweet)
      model = GPTClient::GOOD_MODEL
      tweet = generate_tweet(input, model: model, temperature: temperature) # try again
    end

    response =
      if bad_tweet?(tweet)
        puts "bad tweet: \"#{tweet}\""
        text_block("¯\\_(ツ)_/¯")
      else
        tweet_block(tweet, model: model, temperature: temperature)
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
        /^(can|what|who|why|how|would|is|are|could|how|should|do|where|which|if)\s/ ||
        input[-1] == "?"

    too_many_words || too_long || question
  end

  def bad_tweet?(tweet)
    sorry = tweet[0, 20] =~ /sorry/i
    im_sorry = tweet =~ /^(i['’]?m sorry|i am sorry)/i
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

  def tweet_block(tweet, model: nil, temperature: nil)
    byline = "Twitter | "

    if model && temperature
      byline << "#{model} | t:#{temperature}"
    elsif model
      byline << "#{model}"
    else
      byline << now
    end

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
            { type: "mrkdwn", text: byline }
          ]
        }
      ]
    }
  end

  def generate_tweet(input, model: nil, temperature: nil)
    @gpt_client.chat(
      input,
      prompt: build_prompt(input),
      model: model,
      temperature: temperature
    )
  end

  def clean_input(input)
    input = input.downcase.gsub(INPUT_FILTER, "").strip

    prompt = [
      {
        role: "system",
        content:
          "Your job is to extract the main topic from a phrase that I will give you"
      },
      { role: "user", content: "will I get laid off?" },
      { role: "assistant", content: "layoffs" },
      {
        role: "user",
        content: "write an inspiring story about working in tech"
      },
      { role: "assistant", content: "inspiring tech story" },
      { role: "user", content: "do gamers have drip?" },
      { role: "assistant", content: "gamer drip" },
      { role: "user", content: "write an inspiring linkedin post" },
      { role: "assistant", content: "inspirational linkedin post" },
      {
        role: "user",
        content: "are electrical vehicles better for the environment"
      },
      { role: "assistant", content: "electric vehicles" }
    ]

    new_input =
      @gpt_client.chat(input, prompt: prompt, model: GPTClient::GOOD_MODEL)

    new_input = new_input.downcase.gsub(/\.$/, "").gsub(INPUT_FILTER, "")

    if input != new_input
      puts "change input from \"#{input}\" to \"#{new_input}\""
    end

    new_input
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
      Tweet
        .where(
          "id < ?",
          1800
        ) # this is roughly the beginning of golden age mylo content
        .nearest_neighbors(:embedding, embedding, distance: :cosine)
        .limit(NEIGHBOR_TWEETS)

    system_prompt = {
      role: "system",
      content:
        "Your job is to mimic the style of these example messages for different user prompts."
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

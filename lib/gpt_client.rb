class GPTClient
  EMBEDDINGS_MODEL = "text-embedding-ada-002"
  CHEAP_MODEL = "gpt-3.5-turbo"
  GOOD_MODEL = "gpt-4"
  GOOD_MODEL_PERCENTAGE = 0.1
  MAX_TOKENS = 100
  DEFAULT_TEMPERATURE = 0.5
  MYLO_USER_ID = "U01695SLPDJ"
  REDIS = RedisClient.new(url: ENV["REDIS_URL"])
  GOOD_MODEL_EXPIRY_HOURS = 18

  def self.select_model(user_id)
    if user_id == MYLO_USER_ID
      GPTClient::GOOD_MODEL
    elsif force_good_model?(user_id)
      GOOD_MODEL
    else
      rand < GOOD_MODEL_PERCENTAGE ? GOOD_MODEL : CHEAP_MODEL
    end
  end

  def self.force_good_model?(user_id)
    key = "forced_good_model_at:#{user_id}"
    forced_good_model_at = REDIS.call("GET", key)&.to_i || 0
    expiry = forced_good_model_at + 60 * 60 * GOOD_MODEL_EXPIRY_HOURS
    force_good_model = Time.now.to_i > expiry
    REDIS.call("SET", key, Time.now.to_i) if force_good_model

    return force_good_model
  end

  def initialize
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
  end

  def chat(
    messages,
    prompt: nil,
    model: CHEAP_MODEL,
    temperature: DEFAULT_TEMPERATURE
  )
    messages = [{ role: "user", content: messages }] if messages.is_a?(String)
    messages = prompt + messages if prompt

    Timeout.timeout(30) do
      response =
        @client.chat(
          parameters: {
            model: model,
            messages: messages,
            temperature: temperature,
            max_tokens: MAX_TOKENS
          }
        )

      response.dig("choices", 0, "message", "content")
    end
  end

  def embedding(input)
    response =
      @client.embeddings(parameters: { model: EMBEDDINGS_MODEL, input: input })

    response.dig("data", 0, "embedding")
  end
end

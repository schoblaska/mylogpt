class GPTClient
  def initialize
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
  end

  def chat(message, add_prompt: false)
    Timeout.timeout(30) do
      message = [{ role: "user", content: message }] if message.is_a?(String)
      message = PROMPT + message if add_prompt

      response =
        @client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: message,
            temperature: 0.5
          }
        )

      response.dig("choices", 0, "message", "content")
    end
  end
end

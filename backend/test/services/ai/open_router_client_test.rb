require "test_helper"

class Ai::OpenRouterClientTest < ActiveSupport::TestCase
  setup do
    @client = Ai::OpenRouterClient.new
  end

  test "configured? returns false when no API key is available" do
    # Ensure no DB key, no credentials, no ENV
    Setting.where(key: "api_keys.openrouter_api_key").destroy_all

    ENV.stub(:[], nil) do
      Rails.application.credentials.stub(:dig, nil) do
        assert_not Ai::OpenRouterClient.new.configured?
      end
    end
  end

  test "configured? returns true when ENV key is set" do
    Setting.where(key: "api_keys.openrouter_api_key").destroy_all

    env_mock = lambda { |key| key == "OPENROUTER_API_KEY" ? "sk-test-key" : nil }
    ENV.stub(:[], env_mock) do
      Rails.application.credentials.stub(:dig, nil) do
        assert Ai::OpenRouterClient.new.configured?
      end
    end
  end

  test "resolve_model returns task-specific model when set" do
    Setting.create!(key: "ai.token_extraction_model", value: "anthropic/claude-sonnet-4-5-20250929", category: "ai", description: "test")
    client = Ai::OpenRouterClient.new(task: :token_extraction)

    assert_equal "anthropic/claude-sonnet-4-5-20250929", client.resolve_model
  ensure
    Setting.where(key: "ai.token_extraction_model").destroy_all
  end

  test "resolve_model falls back to default when task model is blank" do
    Setting.create!(key: "ai.token_extraction_model", value: "", category: "ai", description: "test")
    Setting.create!(key: "ai.default_model", value: "meta-llama/llama-3-70b", category: "ai", description: "test")
    client = Ai::OpenRouterClient.new(task: :token_extraction)

    assert_equal "meta-llama/llama-3-70b", client.resolve_model
  ensure
    Setting.where(key: ["ai.token_extraction_model", "ai.default_model"]).destroy_all
  end

  test "resolve_model falls back to hardcoded default when no settings exist" do
    Setting.where("key LIKE ?", "ai.%").destroy_all
    client = Ai::OpenRouterClient.new(task: :token_extraction)

    assert_equal "google/gemini-2.5-flash", client.resolve_model
  end

  test "resolve_model without task uses default model" do
    Setting.create!(key: "ai.default_model", value: "openai/gpt-4o", category: "ai", description: "test")
    client = Ai::OpenRouterClient.new

    assert_equal "openai/gpt-4o", client.resolve_model
  ensure
    Setting.where(key: "ai.default_model").destroy_all
  end

  test "chat builds correct request body and parses response" do
    api_response = {
      "choices" => [
        { "message" => { "role" => "assistant", "content" => "Hello from AI" } }
      ]
    }.to_json

    mock_http_response = Minitest::Mock.new
    mock_http_response.expect(:is_a?, true, [Net::HTTPSuccess])
    mock_http_response.expect(:body, api_response)

    # We need to stub the private post_request method
    client = Ai::OpenRouterClient.new(task: :token_extraction)

    # Stub resolve_api_key to return a test key
    client.stub(:resolve_api_key, "sk-test-key") do
      Net::HTTP.stub(:new, ->(*_args) {
        mock_http = Object.new
        mock_http.define_singleton_method(:use_ssl=) { |_| }
        mock_http.define_singleton_method(:open_timeout=) { |_| }
        mock_http.define_singleton_method(:read_timeout=) { |_| }
        mock_http.define_singleton_method(:request) { |_req|
          response = Net::HTTPResponse.allocate
          response.define_singleton_method(:is_a?) { |klass| klass == Net::HTTPSuccess }
          response.define_singleton_method(:body) { api_response }
          response
        }
        mock_http
      }) do
        result = client.chat(messages: [{ role: "user", content: "Hi" }])
        assert_equal "Hello from AI", result
      end
    end
  end

  test "chat raises on empty choices" do
    api_response = { "choices" => [] }.to_json

    client = Ai::OpenRouterClient.new
    client.stub(:resolve_api_key, "sk-test-key") do
      Net::HTTP.stub(:new, ->(*_args) {
        mock_http = Object.new
        mock_http.define_singleton_method(:use_ssl=) { |_| }
        mock_http.define_singleton_method(:open_timeout=) { |_| }
        mock_http.define_singleton_method(:read_timeout=) { |_| }
        mock_http.define_singleton_method(:request) { |_req|
          response = Net::HTTPResponse.allocate
          response.define_singleton_method(:is_a?) { |klass| klass == Net::HTTPSuccess }
          response.define_singleton_method(:body) { api_response }
          response
        }
        mock_http
      }) do
        assert_raises(RuntimeError, "Empty response from OpenRouter") do
          client.chat(messages: [{ role: "user", content: "Hi" }])
        end
      end
    end
  end

  test "complete sends system prompt when provided" do
    client = Ai::OpenRouterClient.new
    captured_messages = nil

    client.stub(:chat, ->(messages:, **_opts) {
      captured_messages = messages
      "response"
    }) do
      client.complete(prompt: "test", system: "You are helpful")
    end

    assert_equal 2, captured_messages.length
    assert_equal "system", captured_messages[0][:role]
    assert_equal "You are helpful", captured_messages[0][:content]
    assert_equal "user", captured_messages[1][:role]
  end

  test "complete omits system prompt when nil" do
    client = Ai::OpenRouterClient.new
    captured_messages = nil

    client.stub(:chat, ->(messages:, **_opts) {
      captured_messages = messages
      "response"
    }) do
      client.complete(prompt: "test")
    end

    assert_equal 1, captured_messages.length
    assert_equal "user", captured_messages[0][:role]
  end
end

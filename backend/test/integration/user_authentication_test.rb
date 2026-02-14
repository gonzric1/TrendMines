require "test_helper"

class UserAuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @unique_id = SecureRandom.hex(4)
    @email = "auth-test-#{@unique_id}@example.com"
    @user_params = {
      user: {
        email: @email,
        password: "password123",
        password_confirmation: "password123",
        name: "Test User"
      }
    }
  end

  test "user can register with valid credentials" do
    post user_registration_path, params: @user_params, as: :json

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal "User registered successfully", json_response["message"]
    assert_equal @email, json_response["user"]["email"]
    assert_equal "Test User", json_response["user"]["name"]
    assert_equal "operator", json_response["user"]["role"]
  end

  test "registration fails with missing required fields" do
    invalid_params = {
      user: {
        email: @email,
        password: "password123"
        # Missing password_confirmation and name
      }
    }
    post user_registration_path, params: invalid_params, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "user can sign in with valid credentials and receives JWT token" do
    User.create!(
      email: @email,
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      role: :operator
    )

    post user_session_path, params: {
      user: { email: @email, password: "password123" }
    }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal "Signed in successfully", json_response["message"]
    assert json_response["user"].present?

    # Check that Authorization header is present (JWT token)
    assert response.headers["Authorization"].present?
  end

  test "sign in fails with invalid credentials" do
    post user_session_path, params: {
      user: {
        email: "nonexistent@example.com",
        password: "wrongpassword"
      }
    }, as: :json

    assert_response :unauthorized
  end

  test "user can sign out" do
    User.create!(
      email: @email,
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      role: :operator
    )

    post user_session_path, params: {
      user: { email: @email, password: "password123" }
    }, as: :json

    token = response.headers["Authorization"]

    delete destroy_user_session_path,
           headers: { "Authorization" => token },
           as: :json

    assert_response :no_content
  end

  test "API key authentication still works for OpenClaw endpoints" do
    get api_v1_niches_path,
        headers: { "X-API-Key" => "test-api-key-for-test-suite" },
        as: :json

    assert_response :success
  end

  test "protected endpoints reject unauthenticated requests" do
    get api_v1_niches_path, as: :json

    assert_response :unauthorized
  end

  test "protected endpoints accept authenticated user JWT" do
    User.create!(
      email: @email,
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      role: :operator
    )

    post user_session_path, params: {
      user: { email: @email, password: "password123" }
    }, as: :json

    token = response.headers["Authorization"]

    get api_v1_niches_path,
        headers: { "Authorization" => token },
        as: :json

    assert_response :success
  end
end

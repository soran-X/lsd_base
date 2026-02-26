OmniAuth.config.test_mode = true

def mock_google_oauth(email: "oauth@example.com", uid: "google-uid-123")
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
    provider: "google_oauth2",
    uid: uid,
    info: OmniAuth::AuthHash::InfoHash.new(
      email: email,
      name: "Test OAuth User"
    ),
    credentials: OmniAuth::AuthHash.new(token: "token", expires_at: 1.hour.from_now.to_i)
  )
end

def mock_google_oauth_failure
  OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
end

RSpec.configure do |config|
  config.before(:each, type: :request) { OmniAuth.config.test_mode = true }
  config.before(:each, type: :system) do
    OmniAuth.config.test_mode = true
    # Allow GET requests so Capybara's `visit` can trigger the request phase
    OmniAuth.config.allowed_request_methods = %i[get post]
  end

  config.after(:each) do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.allowed_request_methods = %i[post]
  end
end

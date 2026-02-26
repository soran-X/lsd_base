class Rack::Attack
  # Safelist localhost in test/development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1" if Rails.env.development? || Rails.env.test?
  end

  # Throttle login attempts by IP: 5 per 20 seconds
  throttle("logins/ip", limit: 5, period: 20) do |req|
    req.ip if req.path == "/sign_in" && req.post?
  end

  # Throttle login attempts by email: 5 per 20 seconds
  throttle("logins/email", limit: 5, period: 20) do |req|
    if req.path == "/sign_in" && req.post?
      req.params["email"].to_s.downcase.strip.presence
    end
  end
end

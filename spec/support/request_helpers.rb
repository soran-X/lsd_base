module RequestHelpers
  # Signs in a user by posting to the sign_in path and setting the session cookie.
  def sign_in_as(user, password: "Password1!Pw")
    post sign_in_path, params: { email: user.email, password: password }
  end

  # Signs in by injecting the session cookie directly (faster, no HTTP round-trip).
  def sign_in_via_session(user)
    session_record = user.sessions.create!
    cookies.signed[:session_token] = session_record.id
  end
end

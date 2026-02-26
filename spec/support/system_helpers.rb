module SystemHelpers
  def sign_in_as(user, password: "Password1!Pw")
    visit sign_in_path
    fill_in "Email",    with: user.email
    fill_in "Password", with: password
    click_on "Sign in"
  end

  def sign_out
    find("button", text: "Sign out").click
  end
end

require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:approved_user) { create(:user, :approved, password: "Password1!Pw", password_confirmation: "Password1!Pw") }
  let(:unapproved_user) { create(:user, :unapproved, password: "Password1!Pw", password_confirmation: "Password1!Pw") }

  describe "GET /sign_in" do
    it "is accessible without authentication" do
      get sign_in_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /sign_in" do
    context "with valid credentials" do
      before { approved_user }

      it "signs in and redirects to root" do
        post sign_in_path, params: { email: approved_user.email, password: "Password1!Pw" }
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid credentials" do
      it "redirects back to sign_in with alert" do
        post sign_in_path, params: { email: "wrong@example.com", password: "wrongpassword" }
        expect(response).to redirect_to(sign_in_path(email_hint: "wrong@example.com"))
      end
    end
  end

  describe "DELETE /sessions/:id" do
    it "signs out the user" do
      sign_in_as(approved_user)
      session_rec = Session.last
      delete session_path(session_rec)
      expect(response).to redirect_to(sessions_path)
    end
  end
end

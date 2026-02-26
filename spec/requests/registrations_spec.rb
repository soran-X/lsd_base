require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  describe "GET /sign_up" do
    context "when public signup is enabled" do
      before { create(:site_setting, :signup_enabled) }

      it "returns 200" do
        get sign_up_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when public signup is disabled" do
      before { create(:site_setting, :signup_disabled) }

      it "redirects to sign_in with alert" do
        get sign_up_path
        expect(response).to redirect_to(sign_in_path)
        follow_redirect!
        expect(response.body).to include("disabled")
      end
    end
  end

  describe "POST /sign_up" do
    before { create(:site_setting, :signup_enabled) }

    context "with valid params" do
      it "creates a user and redirects" do
        expect {
          post sign_up_path, params: {
            email: "new@example.com",
            password: "Password1!Pw",
            password_confirmation: "Password1!Pw"
          }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
      end

      it "assigns client role to new user" do
        client_role = create(:role, :client)
        post sign_up_path, params: {
          email: "new2@example.com",
          password: "Password1!Pw",
          password_confirmation: "Password1!Pw"
        }
        expect(User.last.role).to eq(client_role)
      end
    end

    context "with invalid params" do
      it "does not create user and re-renders form" do
        expect {
          post sign_up_path, params: {
            email: "bad",
            password: "short",
            password_confirmation: "short"
          }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when signup is disabled" do
      before { SiteSetting.find_by(key: "allow_public_signup")&.update!(value: "false") }

      it "blocks registration" do
        post sign_up_path, params: {
          email: "blocked@example.com",
          password: "Password1!Pw",
          password_confirmation: "Password1!Pw"
        }
        expect(response).to redirect_to(sign_in_path)
      end
    end
  end
end

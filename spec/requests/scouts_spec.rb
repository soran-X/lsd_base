require 'rails_helper'

RSpec.describe "Scouts", type: :request do
  let(:approved_user) { create(:user, :approved) }
  let(:scout) { create(:scout) }

  context "when not authenticated" do
    it "redirects to sign_in" do
      get scouts_path
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context "when authenticated as approved user" do
    before { sign_in_as(approved_user) }

    describe "GET /scouts" do
      it "returns 200" do
        get scouts_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /scouts/:id" do
      it "returns 200" do
        get scout_path(scout)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /scouts" do
      it "creates scout and redirects" do
        expect {
          post scouts_path, params: { scout: { name: "Scout One", specialty: "Talent", notes: "Note" } }
        }.to change(Scout, :count).by(1)
        expect(response).to redirect_to(scout_path(Scout.last))
      end

      it "returns 422 on invalid params" do
        post scouts_path, params: { scout: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /scouts/:id" do
      it "updates and redirects" do
        patch scout_path(scout), params: { scout: { name: "Updated Scout" } }
        expect(response).to redirect_to(scout_path(scout))
        expect(scout.reload.name).to eq("Updated Scout")
      end
    end

    describe "DELETE /scouts/:id" do
      it "destroys and redirects" do
        scout
        expect { delete scout_path(scout) }.to change(Scout, :count).by(-1)
        expect(response).to redirect_to(scouts_path)
      end
    end
  end
end

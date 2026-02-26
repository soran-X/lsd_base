require 'rails_helper'

RSpec.describe "Authors", type: :request do
  let(:approved_user) { create(:user, :approved) }
  let(:author) { create(:author) }

  context "when not authenticated" do
    it "redirects to sign_in" do
      get authors_path
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context "when authenticated as approved user" do
    before { sign_in_as(approved_user) }

    describe "GET /authors" do
      it "returns 200" do
        get authors_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /authors/:id" do
      it "returns 200" do
        get author_path(author)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /authors" do
      it "creates author and redirects" do
        expect {
          post authors_path, params: { author: { name: "New Author", bio: "Bio text here" } }
        }.to change(Author, :count).by(1)
        expect(response).to redirect_to(author_path(Author.last))
      end

      it "returns 422 on invalid params" do
        post authors_path, params: { author: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /authors/:id" do
      it "updates and redirects" do
        patch author_path(author), params: { author: { name: "Updated Name" } }
        expect(response).to redirect_to(author_path(author))
        expect(author.reload.name).to eq("Updated Name")
      end
    end

    describe "DELETE /authors/:id" do
      it "destroys and redirects" do
        author
        expect { delete author_path(author) }.to change(Author, :count).by(-1)
        expect(response).to redirect_to(authors_path)
      end
    end
  end
end

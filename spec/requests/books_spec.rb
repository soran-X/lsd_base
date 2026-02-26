require 'rails_helper'

RSpec.describe "Books", type: :request do
  let(:approved_user) { create(:user, :approved) }
  let(:book) { create(:book) }

  context "when not authenticated" do
    it "redirects GET /books to sign_in" do
      get books_path
      expect(response).to redirect_to(sign_in_path)
    end
  end

  context "when authenticated as approved user" do
    before { sign_in_as(approved_user) }

    describe "GET /books" do
      it "returns 200" do
        get books_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /books/:id" do
      it "returns 200" do
        get book_path(book)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /books/new" do
      it "returns 200" do
        get new_book_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /books" do
      let(:author) { create(:author) }

      it "creates a book and redirects" do
        expect {
          post books_path, params: { book: { title: "New Book", author_id: author.id, description: "Desc", published_at: Date.today } }
        }.to change(Book, :count).by(1)
        expect(response).to redirect_to(book_path(Book.last))
      end

      it "renders errors on invalid input" do
        post books_path, params: { book: { title: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /books/:id" do
      it "updates and redirects" do
        patch book_path(book), params: { book: { title: "Updated Title" } }
        expect(response).to redirect_to(book_path(book))
        expect(book.reload.title).to eq("Updated Title")
      end
    end

    describe "DELETE /books/:id" do
      it "destroys the book and redirects" do
        book
        expect { delete book_path(book) }.to change(Book, :count).by(-1)
        expect(response).to redirect_to(books_path)
      end
    end
  end

  context "when unapproved" do
    let(:unapproved) { create(:user, :unapproved) }

    before { sign_in_as(unapproved) }

    it "redirects to pending_approval" do
      get books_path
      expect(response).to redirect_to(pending_approval_path)
    end
  end
end

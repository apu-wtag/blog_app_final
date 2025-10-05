require 'rails_helper'

RSpec.describe "Comments", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let!(:comment) { create(:comment, article: article, user: user) }

  describe "POST /articles/:article_id/comments (create)" do
    let(:valid_attributes) { { body: "This is a new comment." } }

    context "as a guest" do
      it "redirects to the login page" do
        post article_comments_path(article), params: { comment: valid_attributes }
        expect(response).to redirect_to(login_path)
      end
    end

    context "as an authenticated user" do
      before { sign_in user }

      it "creates a new top-level comment with valid parameters" do
        expect {
          post article_comments_path(article), params: { comment: valid_attributes }, as: :turbo_stream
        }.to change(Comment, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq Mime[:turbo_stream]
      end

      it "creates a new reply with a parent_id" do
        reply_attributes = { body: "This is a reply.", parent_id: comment.id }
        expect {
          post article_comments_path(article), params: { comment: reply_attributes }, as: :turbo_stream
        }.to change(comment.replies, :count).by(1)
        expect(response).to have_http_status(:ok)
      end

      it "does not create a comment with invalid parameters" do
        expect {
          post article_comments_path(article), params: { comment: { body: "" } }, as: :turbo_stream
        }.not_to change(Comment, :count)
        expect(response).to redirect_to(article_path(article))
      end
    end
  end

  describe "PATCH /articles/:article_id/comments/:id (update)" do
    context "as the comment owner" do
      before { sign_in user }

      it "updates the comment with valid parameters" do
        patch article_comment_path(article, comment), params: { comment: { body: "Updated body." } }, as: :turbo_stream
        expect(comment.reload.body).to eq("Updated body.")
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq Mime[:turbo_stream]
      end
    end

    context "as another user" do
      before { sign_in other_user }

      it "is forbidden" do
        patch article_comment_path(article, comment), params: { comment: { body: "Malicious update." } }
        expect(comment.reload.body).not_to eq("Malicious update.")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /articles/:article_id/comments/:id (destroy)" do
    context "as the comment owner" do
      before { sign_in user }

      it "discards the comment" do
        expect {
          delete article_comment_path(article, comment), as: :turbo_stream
        }.to change(Comment.kept, :count)

        expect(comment.reload.discarded?).to be true
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq Mime[:turbo_stream]
      end
      it "discards the comment and its replies" do
        parent_comment = create(:comment, article: article, user: user)
        reply1 = create(:comment, article: article, user: user, parent: parent_comment)
        reply2 = create(:comment, article: article, user: user, parent: parent_comment)

        expect {
          delete article_comment_path(article, parent_comment), as: :turbo_stream
        }.to change(Comment.kept, :count).by(-3)

        expect(parent_comment.reload.discarded?).to be true
        expect(reply1.reload.discarded?).to be true
        expect(reply2.reload.discarded?).to be true
      end
    end

    context "as another user" do
      before { sign_in other_user }

      it "is forbidden" do
        delete article_comment_path(article, comment)
        expect(comment.reload.discarded?).to be false
        expect(response).to redirect_to(root_path)
      end
    end
  end
end

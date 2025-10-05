require 'rails_helper'

RSpec.describe "Articles", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  let!(:kept_article) { create(:article, user: user) }
  let!(:discarded_article) { create(:article, :discarded, user: user) }
  let!(:archived_article) { create(:article, :archived, user: user) }

  describe "GET /articles (index)" do
    it "succeeds and shows only kept articles" do
      get articles_path
      expect(response).to be_successful
      expect_body_to_include(kept_article.title)
      expect_body_not_to_include(discarded_article.title)
      expect_body_not_to_include(archived_article.title)
    end

    it "filters articles by a search query" do
      searched_article = create(:article, title: "Unique Searchable Title")
      get articles_path, params: { query: "Unique Searchable" }
      expect_body_to_include(searched_article.title)
      expect_body_not_to_include(kept_article.title)
    end
  end

  describe "GET /articles/:id (show)" do
    context "for a kept article" do
      it "is successful for any visitor" do
        get article_path(kept_article)
        expect(response).to be_successful
      end
    end

    context "for a discarded (hidden) article" do
      it "is successful for the owner" do
        sign_in user
        get article_path(discarded_article)
        expect(response).to be_successful
      end

      it "redirects another user" do
        sign_in other_user
        get article_path(discarded_article)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "for an archived article" do
      it "redirects to the root path for any user, including the owner" do
        sign_in user
        get article_path(archived_article)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to match(/not found/)
      end
    end
  end

  describe "POST /articles (create)" do
    context "as a guest" do
      it "redirects to the login page" do
        post articles_path, params: { article: { title: "New Title", topic_name: "New Topic" } }
        expect(response).to redirect_to(login_path)
      end
    end

    context "as an authenticated user" do
      before { sign_in user }

      it "creates a new article with valid parameters" do
        valid_attributes = { title: "A Valid Title which is acceptable", topic_name: "A Valid Topic", content: attributes_for(:article)[:content] }
        expect {
          post articles_path, params: { article: valid_attributes }
        }.to change(Article, :count).by(1)
        expect(response).to redirect_to(Article.last)
      end

      it "does not create an article with invalid parameters" do
        invalid_attributes = { title: "" }
        expect {
          post articles_path, params: { article: invalid_attributes }
        }.not_to change(Article, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  describe "PATCH /articles/:id (update)" do
    context "as the article owner" do
      before { sign_in user }

      it "updates the article with valid parameters" do
        patch article_path(kept_article), params: { article: { title: "A New Updated Title" } }
        expect(kept_article.reload.title).to eq("A New Updated Title")
        expect(response).to redirect_to(kept_article)
      end
    end

    context "as an admin (who is not the owner)" do
      before { sign_in admin }

      it "is forbidden from updating an article they do not own" do
        patch article_path(kept_article), params: { article: { title: "Updated by Admin" } }

        expect(kept_article.reload.title).not_to eq("Updated by Admin")

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "as another user" do
      before { sign_in other_user }

      it "is forbidden" do
        patch article_path(kept_article), params: { article: { title: "Should Not Work" } }
        expect(kept_article.reload.title).not_to eq("Should Not Work")
        expect(response).to redirect_to(root_path)
      end
    end

    context "when the owner updates their own discarded article (Request Review)" do
      let!(:hidden_record) { create(:moderation_record, status: :hidden, article: discarded_article, admin: admin) }
      before { sign_in user }

      it "updates the article and creates a pending moderation record" do
        expect {
          patch article_path(discarded_article), params: {
            article: {
              title: "Title fixed, please review",
              author_note: "I have fixed the issues."
            }
          }
        }.to change(ModerationRecord, :count).by(0)

        discarded_article.reload

        expect(response).to redirect_to(discarded_article)
        expect(flash[:notice]).to eq("Article updated and submitted for review.")
        expect(hidden_record.reload.pending_review?).to be true
        expect(hidden_record.reload.author_note).to eq("I have fixed the issues.")
      end
    end
  end

  describe "DELETE /articles/:id (destroy/archive)" do
    context "as the article owner" do
      before { sign_in user }

      it "archives the article" do
        delete article_path(kept_article)
        expect(kept_article.reload.archived_at).not_to be nil
        expect(response).to redirect_to(articles_path)
      end
    end

    context "as another user" do
      before { sign_in other_user }

      it "is forbidden and redirects with an alert" do
        delete article_path(kept_article)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end
  end

  describe "POST /articles/:id/toggle_clap" do
    context "as an authenticated user" do
      before { sign_in user }

      it "creates a clap for an un-clapped article" do
        expect {
          post toggle_clap_article_path(kept_article), as: :turbo_stream
        }.to change(Clap, :count).by(1)
      end

      it "destroys a clap for a clapped article" do
        create(:clap, user: user, article: kept_article)
        expect {
          post toggle_clap_article_path(kept_article), as: :turbo_stream
        }.to change(Clap, :count).by(-1)
      end
    end
  end
end

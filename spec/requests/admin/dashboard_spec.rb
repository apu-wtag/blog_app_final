require 'rails_helper'

RSpec.describe "Admin::Dashboard", type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe "GET /admin (index)" do
    context "as a guest" do
      it "redirects to the root path" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "as a non-admin user" do
      before { sign_in user }

      it "redirects to the root path" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "as an admin" do
      let!(:users) { create_list(:user, 3) }
      let!(:kept_articles) { create_list(:article, 5) }
      let!(:archived_article) { create(:article, :archived) }
      let!(:comments) { create_list(:comment, 4) }
      let!(:claps) { create_list(:clap, 6) }

      let!(:reported_article) { create(:article) }
      let!(:report_on_article) { create(:report, reportable: reported_article) }

      let!(:article_for_review) { create(:article, :discarded) }
      let!(:review_request) { create(:moderation_record, :pending_review, article: article_for_review) }

      let!(:reported_comment) { create(:comment) }
      let!(:report_on_comment) { create(:report, reportable: reported_comment) }

      let!(:popular_article) { create(:article, claps_count: 100) }
      let!(:commented_article) { create(:article, comments_count: 50) }

      before do
        sign_in admin
        get admin_root_path
      end

      it "is successful" do
        expect(response).to be_successful
      end

      it "assigns the correct total counts" do
        expect(assigns(:total_users)).to eq(User.count)
        expect(assigns(:total_articles)).to eq(Article.not_archived.count)
        expect(assigns(:total_comments)).to eq(Comment.count)
        expect(assigns(:total_claps)).to eq(Clap.count)
      end

      it "assigns the correct items to the unified moderation queue" do
        actionable_items = assigns(:actionable_items)
        expect(actionable_items).to include(reported_article)
        expect(actionable_items).to include(article_for_review)
        expect(actionable_items).to include(reported_comment)
        expect(actionable_items).not_to include(kept_articles.first)
      end

      it "assigns the correct articles to the spotlight sections" do
        expect(assigns(:most_clapped_articles)).to include(popular_article)
        expect(assigns(:most_commented_articles)).to include(commented_article)
      end
    end
  end
end

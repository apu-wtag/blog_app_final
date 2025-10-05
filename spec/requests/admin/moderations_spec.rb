require 'rails_helper'

RSpec.describe "Admin::Moderations", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  describe "GET /admin/moderation (show)" do
    context "as a non-admin" do
      it "is forbidden" do
        sign_in user
        get admin_moderation_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "as an admin" do
      before { sign_in admin }

      context "with the default 'articles' scope" do
        let!(:reported_article) { create(:article) }
        let!(:report) { create(:report, reportable: reported_article, status: :pending) }

        let!(:article_for_review) { create(:article, :discarded) }
        let!(:review_request) { create(:moderation_record, article: article_for_review, status: :pending_review) }

        let!(:normal_article) { create(:article) }
        let!(:archived_article_with_report) { create(:article, :archived) }
        let!(:report_on_archived) { create(:report, reportable: archived_article_with_report, status: :pending) }

        before { get admin_moderation_path }

        it "is successful" do
          expect(response).to be_successful
        end

        it "assigns a unified list of actionable articles" do
          results = assigns(:results)
          expect(results).to include(reported_article)
          expect(results).to include(article_for_review)
        end

        it "does not include articles that do not need action" do
          results = assigns(:results)
          expect(results).not_to include(normal_article)
          expect(results).not_to include(archived_article_with_report)
        end
      end

      context "with the 'comments' scope" do
        let!(:reported_comment) { create(:comment) }
        let!(:report_on_comment) { create(:report, reportable: reported_comment, status: :pending) }
        let!(:normal_comment) { create(:comment) }

        before { get admin_moderation_path, params: { scope: 'comments' } }

        it "is successful" do
          expect(response).to be_successful
        end

        it "assigns a list of reported comments" do
          results = assigns(:results)
          expect(results).to include(reported_comment)
          expect(results).not_to include(normal_comment)
        end
      end
    end
  end
end

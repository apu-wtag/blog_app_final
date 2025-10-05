require 'rails_helper'

RSpec.describe "Admin::Articles", type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:author) { create(:user) }
  let!(:article) { create(:article, user: author) }

  context "as a non-admin" do
    it "is forbidden from accessing any action" do
      sign_in author
      patch hide_admin_article_path(article), params: { article: { admin_reason: "Test" } }
      expect(response).to redirect_to(root_path)
    end
  end

  context "as an admin" do
    before do
      sign_in admin
    end

    describe "Report Handling Actions" do
      let!(:report) { create(:report, reportable: article) }

      it "resolves pending reports" do
        patch resolve_reports_admin_article_path(article)
        expect(report.reload.resolved?).to be true
        expect(response).to redirect_to(admin_moderation_path)
      end

      it "dismisses pending reports" do
        patch dismiss_reports_admin_article_path(article)
        expect(report.reload.dismissed?).to be true
        expect(response).to redirect_to(admin_moderation_path)
      end
    end

    describe "Hiding an Article" do
      let!(:report) { create(:report, reportable: article) }

      it "discards the article, resolves reports, creates a record, and enqueues a job" do
        expect {
          patch hide_admin_article_path(article), params: { article: { admin_reason: "Test reason" } }
        }.to change(ModerationRecord, :count).by(1)

        expect(article.reload.discarded?).to be true
        expect(report.reload.resolved?).to be true

        last_record = ModerationRecord.last
        expect(last_record.hidden?).to be true
        expect(last_record.admin_reason).to eq("Test reason")

        expect(AuthorNotifierJob.jobs.size).to eq(1)
        expect(response).to redirect_to(admin_moderation_path)
      end
    end

    describe "Reviewing a Restoration Request" do
      let!(:discarded_article) { create(:article, :discarded, user: author) }
      let!(:moderation_record) { create(:moderation_record, :pending_review, article: discarded_article, admin: admin) }

      context "when approving" do
        it "restores the article, updates the record, and enqueues a job" do
          patch approve_restoration_admin_article_path(discarded_article)

          expect(discarded_article.reload.kept?).to be true
          expect(moderation_record.reload.approved?).to be true
          expect(AuthorNotifierJob.jobs.size).to eq(1)
          expect(response).to redirect_to(admin_moderation_path)
        end
      end

      context "when rejecting" do
        it "keeps the article discarded, updates the record, and enqueues a job" do
          patch reject_restoration_admin_article_path(discarded_article), params: { article: { rejection_reason: "Still needs work" } }

          expect(discarded_article.reload.discarded?).to be true
          expect(moderation_record.reload.rejected?).to be true
          expect(moderation_record.reload.rejection_reason).to eq("Still needs work")
          expect(AuthorNotifierJob.jobs.size).to eq(1)
          expect(response).to redirect_to(admin_moderation_path)
        end
      end
    end
  end
end

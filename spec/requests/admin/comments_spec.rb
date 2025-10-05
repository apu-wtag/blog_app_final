require 'rails_helper'

RSpec.describe "Admin::Comments", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let!(:comment) { create(:comment) }

  context "when not logged in as an admin" do
    it "is forbidden from accessing any action" do
      sign_in user
      delete admin_comment_path(comment)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end
  end

  context "when logged in as an admin" do
    let!(:report) { create(:report, reportable: comment) }

    before do
      sign_in admin
    end

    describe "DELETE /admin/comments/:id (destroy/discard)" do
      it "discards the comment and resolves the pending report" do
        delete admin_comment_path(comment)

        expect(comment.reload.discarded?).to be true
        expect(report.reload.resolved?).to be true
        expect(response).to redirect_to(admin_moderation_path(scope: 'comments'))
        expect(flash[:notice]).to match(/Comment was successfully deleted/)
      end
    end

    describe "PATCH /admin/comments/:id/resolve_reports" do
      it "resolves the pending report without discarding the comment" do
        patch resolve_reports_admin_comment_path(comment)

        expect(report.reload.resolved?).to be true
        expect(comment.reload.kept?).to be true
        expect(response).to redirect_to(admin_moderation_path(scope: 'comments'))
        expect(flash[:notice]).to match(/Reports for comment were resolved/)
      end
    end

    describe "PATCH /admin/comments/:id/dismiss_reports" do
      it "dismisses the pending report without discarding the comment" do
        patch dismiss_reports_admin_comment_path(comment)

        expect(report.reload.dismissed?).to be true
        expect(comment.reload.kept?).to be true
        expect(response).to redirect_to(admin_moderation_path(scope: 'comments'))
        expect(flash[:notice]).to match(/Reports for comment were dismissed/)
      end
    end
  end
end

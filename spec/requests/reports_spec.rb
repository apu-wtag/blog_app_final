require 'rails_helper'

RSpec.describe "Reports", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:article) { create(:article, user: other_user) }
  let(:own_article) { create(:article, user: user) }
  let(:comment) { create(:comment, user: other_user, article: article) }
  let(:own_comment) { create(:comment, user: user, article: article) }

  describe "POST /reports (create)" do
    let(:valid_attributes) { { reason: "This is a test report reason." } }
    let(:invalid_attributes) { { reason: "short" } }

    context "as a guest" do
      it "redirects to the login page" do
        post article_reports_path(article), params: { report: valid_attributes }
        expect(response).to redirect_to(login_path)
      end
    end

    context "as an authenticated user" do
      before { sign_in user }

      context "when reporting another user's article" do
        it "creates a new report and redirects to the article" do
          expect {
            post article_reports_path(article), params: { report: valid_attributes }
          }.to change(Report, :count).by(1)
          expect(response).to redirect_to(article_path(article))
          expect(flash[:notice]).to match(/Thank you! Your report has been submitted/)
        end
      end

      context "when reporting their own article" do
        it "is forbidden by the policy" do
          expect {
            post article_reports_path(own_article), params: { report: valid_attributes }
          }.not_to change(Report, :count)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq("You are not authorized to perform this action.")
        end
      end

      context "when reporting another user's comment" do
        it "creates a new report and redirects to the article" do
          expect {
            post article_comment_reports_path(comment.article, comment), params: { report: valid_attributes }
          }.to change(Report, :count).by(1)
          expect(response).to redirect_to(article_path(article))
        end
      end

      context "when reporting their own comment" do
        it "is forbidden by the policy" do
          expect {
            post article_comment_reports_path(own_comment.article, own_comment), params: { report: valid_attributes }
          }.not_to change(Report, :count)
          expect(response).to redirect_to(root_path)
        end
      end

      context "with invalid parameters (e.g., short reason)" do
        it "does not create a report and re-renders the new template" do
          expect {
            post article_reports_path(article), params: { report: invalid_attributes }
          }.not_to change(Report, :count)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end

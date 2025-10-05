require 'rails_helper'

RSpec.describe "PasswordResets", type: :request do
  include ActiveJob::TestHelper

  let!(:user) { create(:user) }
  let!(:discarded_user) { create(:user, :discarded) }

  describe "GET /password_resets/new" do
    it "is successful" do
      get new_password_reset_path
      expect(response).to be_successful
    end
  end

  describe "POST /password_resets" do
    context "with a valid, kept user's email" do
      it "enqueues a reset mailer job and redirects to login" do
        expect {
          post password_resets_path, params: { password_reset: { email: user.email } }
        }.to change(ResetMailerJob.jobs, :size).by(1)

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq("We have sent a password reset link, Please check your email.")
      end
    end

    context "with a discarded user's email" do
      it "does not enqueue a job and redirects" do
        post password_resets_path, params: { password_reset: { email: discarded_user.email } }

        expect(ResetMailerJob.jobs.size).to eq(0)
        expect(response).to redirect_to(sign_up_path)
        expect(flash[:alert]).to eq("This account has been banned. Please use another email or username to sign up.")
      end
    end

    context "with a non-existent email" do
      it "does not enqueue a job and redirects" do
        post password_resets_path, params: { password_reset: { email: "nouser@example.com" } }

        expect(ResetMailerJob.jobs.size).to eq(0)
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to match(/If an account with that email exists/)
      end
    end
  end

  describe "GET /password_resets/:id/edit" do
    before do
      user.create_reset_digest
    end

    it "is successful with a valid token and email" do
      get edit_password_reset_path(user.reset_token, email: user.email)
      expect(response).to be_successful
    end

    it "redirects with an invalid token" do
      get edit_password_reset_path("invalidtoken", email: user.email)
      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to eq("Invalid password reset link")
    end

    it "redirects with an expired token" do
      user.update_attribute(:reset_sent_at, 3.hours.ago)
      get edit_password_reset_path(user.reset_token, email: user.email)
      expect(response).to redirect_to(new_password_reset_path)
      expect(flash[:notice]).to eq("Password reset has expired")
    end
  end

  describe "PATCH /password_resets/:id" do
    before do
      user.create_reset_digest
    end

    context "with valid parameters" do
      it "updates the user's password and redirects to login" do
        old_digest = user.password_digest
        patch password_reset_path(user.reset_token), params: {
          email: user.email,
          user: { password: "NewPassword123!", password_confirmation: "NewPassword123!" }
        }

        expect(user.reload.password_digest).not_to eq(old_digest)
        expect(user.reload.reset_digest).to be_nil
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to match(/Password successfully updated/)
      end
    end

    context "with invalid parameters" do
      it "does not update the password with mismatched confirmation" do
        old_digest = user.password_digest
        patch password_reset_path(user.reset_token), params: {
          email: user.email,
          user: { password: "NewPassword123!", password_confirmation: "mismatch" }
        }

        expect(user.reload.password_digest).to eq(old_digest)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, user_name: "testuser", email: "test@example.com", password: "Password123!") }
  let!(:discarded_user) { create(:user, :discarded, user_name: "banneduser", email: "banned@example.com", password: "Password123!") }

  describe "GET /login (new)" do
    it "renders the login page for a guest" do
      get login_path
      expect(response).to be_successful
      expect(response).to render_template(:new)
    end

    it "redirects a logged-in user to the root path" do
      post login_path, params: { session: { login: user.email, password: user.password } }
      get login_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /login (create)" do
    context "with valid credentials for a kept user" do
      it "logs the user in and redirects to the root path" do
        post login_path, params: { session: { login: user.email, password: user.password } }
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("Logged in!")
      end

      it "handles login with username instead of email" do
        post login_path, params: { session: { login: user.user_name, password: user.password } }
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(root_path)
      end

      it "sets a remember_me cookie if selected" do
        post login_path, params: { session: { login: user.email, password: user.password, remember_me: '1' } }
        expect(request.cookie_jar.signed['user_id']).to eq(user.id)
        expect(request.cookie_jar.signed['remember_token']).not_to be_blank
      end
    end

    context "with valid credentials for a discarded (banned) user" do
      it "does not log the user in and shows a banned message" do
        post login_path, params: { session: { login: discarded_user.email, password: discarded_user.password } }
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("This account is banned")
      end
    end

    context "with invalid credentials" do
      it "does not log the user in with an incorrect password" do
        post login_path, params: { session: { login: user.email, password: "wrongpassword" } }
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Invalid email/username or password")
      end

      it "does not log the user in with a non-existent email" do
        post login_path, params: { session: { login: "nouser@example.com", password: "password" } }
        expect(session[:user_id]).to be_nil
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Invalid email/username or password")
      end
    end
  end

  describe "DELETE /logout (destroy)" do
    it "logs the user out and redirects to the login page" do
      post login_path, params: { session: { login: user.email, password: user.password } }
      expect(session[:user_id]).to eq(user.id)

      delete logout_path
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to eq("Logged out!")
    end
  end
end

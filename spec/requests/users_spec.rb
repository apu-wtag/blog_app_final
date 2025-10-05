require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /sign_up (new)" do
    it "is successful for a guest" do
      get sign_up_path
      expect(response).to be_successful
    end

    it "redirects a logged-in user" do
      sign_in user
      get sign_up_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /sign_up (create)" do
    context "with valid parameters" do
      it "creates a new user and redirects to login" do
        valid_attributes = attributes_for(:user)
        expect {
          post sign_up_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
        expect(response).to redirect_to(login_path)
      end
    end

    context "with invalid parameters" do
      it "does not create a new user and re-renders the form" do
        invalid_attributes = attributes_for(:user, email: "invalid")
        expect {
          post sign_up_path, params: { user: invalid_attributes }
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /users/:id (show)" do
    context "when viewing a kept user's profile" do
      let!(:kept_article) { create(:article, user: user) }
      let!(:discarded_article) { create(:article, :discarded, user: user) }
      let!(:archived_article) { create(:article, :archived, user: user) }

      it "is successful" do
        get user_path(user)
        expect(response).to be_successful
      end

      it "displays the user's kept articles" do
        get user_path(user)
        expect_body_to_include(kept_article.title)
      end

      it "does not display the user's archived articles" do
        get user_path(user)
        expect_body_not_to_include(archived_article.title)
      end

      it "displays the user's discarded articles (for the owner)" do
        sign_in user
        get user_path(user)
        expect(response.body).to include("Hidden Articles")
        expect_body_to_include(discarded_article.title)
      end
    end

    context "when trying to view a discarded user's profile" do
      let(:discarded_user) { create(:user, :discarded) }

      it "redirects with a not found notice" do
        get user_path(discarded_user)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to match(/not found/)
      end
    end
  end

  describe "PATCH /users/:id (update)" do
    context "as the profile owner" do
      before { sign_in user }

      it "updates the profile with valid parameters" do
        patch user_path(user), params: { user: { name: "New Name" } }
        expect(user.reload.name).to eq("New Name")
        expect(response).to redirect_to(user_path(user))
      end

      it "does not update the profile with invalid parameters" do
        patch user_path(user), params: { user: { email: "" } }
        expect(user.reload.email).not_to be_blank
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as another user" do
      before { sign_in other_user }

      it "is forbidden" do
        patch user_path(user), params: { user: { name: "Malicious Update" } }
        expect(user.reload.name).not_to eq("Malicious Update")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /users/check_username" do
    let!(:existing_user) { create(:user, user_name: "taken") }

    it "returns available: true for a new username" do
      get check_username_users_path, params: { user_name: "available" }
      expect(response.parsed_body["available"]).to be true
    end

    it "returns available: false for a taken username" do
      get check_username_users_path, params: { user_name: "taken" }
      expect(response.parsed_body["available"]).to be false
    end

    it "returns available: true when checking an existing user's own name" do
      get check_username_users_path, params: { user_name: "taken", current_id: existing_user.id }
      expect(response.parsed_body["available"]).to be true
    end
  end
end

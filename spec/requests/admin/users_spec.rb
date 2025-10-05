require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  context "when not logged in as an admin" do
    it "redirects non-admins from the index page" do
      sign_in user
      get admin_users_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end
  end

  context "when logged in as an admin" do
    before do
      sign_in admin
    end

    describe "GET /admin/users (index)" do
      let!(:users) { create_list(:user, 5) }

      it "is successful" do
        get admin_users_path
        expect(response).to be_successful
      end

      it "displays a list of users" do
        get admin_users_path
        expect_body_to_include(users.first.name)
        expect_body_to_include(users.last.name)
      end

      it "filters users by a search query" do
        unique_user = create(:user, name: "UniqueSearchableName")
        get admin_users_path, params: { query: "UniqueSearchableName" }
        expect_body_to_include(unique_user.name)
        expect_body_not_to_include(users.first.name)
      end
    end

    describe "DELETE /admin/users/:id (destroy/discard)" do
      let!(:user_to_discard) { create(:user) }

      it "discards the specified user" do
        delete admin_user_path(user_to_discard)
        expect(user_to_discard.reload.discarded?).to be true
        expect(response).to redirect_to(admin_users_path)
        expect(flash[:notice]).to eq("User was successfully deleted.")
      end

      it "prevents an admin from discarding their own account" do
        delete admin_user_path(admin)
        expect(admin.reload.discarded?).to be false
        expect(response).to redirect_to(admin_users_path)
        expect(flash[:notice]).to eq("You cannot delete your own account.")
      end
    end

    describe "PATCH /admin/users/:id/restore" do
      let!(:discarded_user) { create(:user, :discarded) }

      it "restores the specified discarded user" do
        patch restore_admin_user_path(discarded_user)
        expect(discarded_user.reload.kept?).to be true
        expect(response).to redirect_to(admin_users_path)
        expect(flash[:notice]).to match(/was successfully restored/)
      end
    end

    describe "PATCH /admin/users/:id/update_role" do
      let!(:user_to_promote) { create(:user, role: :member) }

      it "updates the user's role" do
        patch update_role_admin_user_path(user_to_promote), params: { user: { role: 'admin' } }
        expect(user_to_promote.reload.admin?).to be true
        expect(response).to redirect_to(admin_users_path)
        expect(flash[:notice]).to match(/role was updated to admin/)
      end
    end
  end
end

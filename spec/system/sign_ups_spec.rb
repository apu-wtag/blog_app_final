require 'rails_helper'

RSpec.describe "User Sign Up", type: :system do
  describe "the sign-up process" do
    it "allows a new user to sign up successfully" do
      visit sign_up_path

      fill_in "Username", with: "new_test_user"
      fill_in "Name", with: "Test User"
      fill_in "Email", with: "new_user@example.com"
      fill_in "Password", with: "Password123!"
      fill_in "Password Confirmation", with: "Password123!"
      fill_in "Bio", with: "This is a test bio."

      attach_file "Profile Picture", Rails.root.join('spec', 'support', 'assets', 'test_avatar.png')

      click_button "Sign Up"

      expect(page).to have_current_path(login_path)
      expect(page).to have_content("Thank you for signing up! Please Login to continue.")

      user = User.last
      expect(user.email).to eq("new_user@example.com")
      expect(user.profile_picture).to be_attached
    end

    it "shows errors for invalid input" do
      visit sign_up_path

      fill_in "Name", with: "Test User"
      fill_in "Email", with: "test@example.com"
      fill_in "Password", with: "Password123!"
      fill_in "Password Confirmation", with: "mismatched"

      click_button "Sign Up"

      expect(User.count).to eq(0)
      expect(page).to have_content("Password confirmation doesn't match Password")
      expect(page).to have_content("Create Account")
    end

    it "blocks a banned user from re-registering" do
      create(:user, :discarded, email: "banned@example.com")

      visit sign_up_path

      fill_in "Name", with: "Banned User"
      fill_in "Email", with: "banned@example.com"
      fill_in "Password", with: "Password123!"
      fill_in "Password Confirmation", with: "Password123!"
      click_button "Sign Up"

      expect(User.count).to eq(1)
      expect(page).to have_content("This account is banned. Please use another email/username.")
    end
  end
end

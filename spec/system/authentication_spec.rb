require 'rails_helper'

RSpec.describe "Authentication", type: :system do
  let!(:user) { create(:user, name: "Test User", email: "test@example.com", password: "Password123!") }
  let!(:discarded_user) { create(:user, :discarded, email: "banned@example.com", password: "Password123!") }

  describe "Login and Logout" do
    it "allows a user to log in successfully, see their name, and log out" do
      visit login_path

      fill_in "session_login", with: "test@example.com"
      fill_in "session_password", with: "Password123!"
      click_button "Log In"

      expect(page).to have_content("Logged in!")

      within "nav.bg-gray-50" do
        expect(page).to have_content("Test User")
        expect(page).to have_button("Logout")
      end


      click_button "Logout"

      expect(page).to have_content("Logged out!")
      within "nav" do
        expect(page).to have_link("Login")
        expect(page).not_to have_content("Test User")
      end
    end

    it "shows an error for an incorrect password" do
      visit login_path

      fill_in "session_login", with: "test@example.com"
      fill_in "session_password", with: "WrongPassword!"
      click_button "Log In"

      expect(page).to have_content("Invalid email/username or password")
      expect(page).not_to have_button("Logout")
    end

    it "blocks a discarded (banned) user from logging in" do
      visit login_path

      fill_in "session_login", with: "banned@example.com"
      fill_in "session_password", with: "Password123!"
      click_button "Log In"

      expect(page).to have_content("This account is banned")
      expect(page).not_to have_button("Logout")
    end

    it "redirects a logged-in user from the login page" do
      visit login_path
      fill_in "session_login", with: "test@example.com"
      fill_in "session_password", with: "Password123!"
      click_button "Log In"
      expect(page).to have_content("Logged in!")

      visit login_path

      expect(page).to have_current_path(root_path)
      expect(page).to have_content("You are already logged in.")
    end
  end
end

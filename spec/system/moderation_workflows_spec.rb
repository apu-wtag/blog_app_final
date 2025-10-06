require 'rails_helper'

RSpec.describe "ModerationWorkflow", type: :system do
  let!(:author) { create(:user, name: "Article Author") }
  let!(:reporter) { create(:user, name: "Concerned Citizen") }
  let!(:admin) { create(:user, :admin, name: "Admin User") }
  let!(:article) { create(:article, user: author, title: "An Article to be Moderated") }

  before do
    driven_by(:selenium_chrome_headless)
    page.driver.browser.manage.window.resize_to(1920,1080)
  end

  def login_as(user)
    visit logout_path if page.has_button?("Logout") || page.has_link?("Logout")
    visit login_path
    fill_in "session_login", with: user.email
    fill_in "session_password", with: user.password
    click_button "Log In"
    expect(page).to have_content("Logged in!")
  end

  it "allows a full report, hide, review, and restoration cycle" do
    # A User Reports an Article
    login_as(reporter)
    visit article_path(article)

    click_link "Report this article"
    fill_in "Please provide a reason for your report:", with: "This is a test report reason."
    click_button "Submit Report"

    expect(page).to have_content("Thank you! Your report has been submitted for review.")
    visit articles_path
    expect(page).to have_button("Logout")
    click_button "Logout"

    # An Admin Hides the Article
    login_as(admin)
    visit admin_moderation_path

    within("#article_#{article.id}") do
      expect(page).to have_content("Reported")
      click_link "Hide"
    end
    within("#article_#{article.id}") do
      fill_in "article_admin_reason", with: "Admin has hidden this for review."
      click_button "Confirm Hide"
    end

    expect(page).to have_content("Article has been hidden.")
    visit root_path
    click_button "Logout"

    # Confirm the article is hidden
    login_as(reporter)
    visit article_path(article)
    expect(page).to have_content("You are not authorized to perform this action.")
    click_button "Logout"

    # The Author Requests Restoration
    login_as(author)
    visit user_path(author)

    expect(page).to have_content("Admin Reason: Admin has hidden this for review.")
    click_link "Edit to Request Review"

    # The author edits the article and adds a note
    fill_in "Title", with: "My Article - Now Updated and Safe"
    fill_in "article_author_note", with: "I have made the required changes."
    click_button "Update & Request Review"

    click_button "Logout"

    # The Admin Approves the Restoration
    login_as(admin)
    visit admin_moderation_path

    within("#article_#{article.id}") do
      expect(page).to have_content("Awaiting Review")
      expect(page).to have_content("Author's Note: \"I have made the required changes.\"")
      click_button "Approve"
    end

    expect(page).to have_content("Article restored and request approved.")
    expect(page).not_to have_content("My Article - Now Updated and Safe")
    visit root_path
    click_button "Logout"

    # FINAL VERIFICATION
    login_as(reporter)
    visit article_path(article)
    expect(page).to have_content("My Article - Now Updated and Safe")
    expect(page).not_to have_content("This article is currently hidden.")
    expect(page).not_to have_content("After saving your changes, this article will be submitted to an administrator for review before it can be restored.")
  end
end

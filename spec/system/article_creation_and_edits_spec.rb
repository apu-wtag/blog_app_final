require 'rails_helper'

RSpec.describe "ArticleCreation", type: :system do
  let!(:user) { create(:user) }

  before do
    visit login_path
    fill_in "session_login", with: user.email
    fill_in "session_password", with: user.password
    click_button "Log In"
    expect(page).to have_content("Logged in!")
  end

  it "allows a user to create and then edit their own article" do
    click_link "New article"

    fill_in "Title", with: "My First Article"
    fill_in "Type to search or create a new topic...", with: "Test Topic"

    find("#article_content").click
    find(".ce-paragraph").send_keys("This is the first paragraph.")
    find(".ce-paragraph").send_keys(:enter)
    find_all(".ce-paragraph").last.send_keys("This is the second paragraph, written after pressing enter.")

    click_button "Publish"

    expect(page).to have_content("Article was successfully created.")
    expect(page).to have_content("My First Article")
    expect(page).to have_content("This is the first paragraph.")
    expect(page).to have_content("This is the second paragraph")

    click_link "Edit"

    fill_in "Title", with: "My Edited Multi-Block Article"
    first_paragraph = find_all(".ce-paragraph").first
    first_paragraph.send_keys([ :control, 'a' ], :backspace)
    first_paragraph.send_keys("This content has been completely replaced.")
    click_button "Publish"

    expect(page).to have_content("Article was successfully updated.")
    expect(page).to have_content("My Edited Multi-Block Article")
    expect(page).to have_content("This content has been completely replaced.")
    expect(page).not_to have_content("This is the first paragraph.")
  end
end

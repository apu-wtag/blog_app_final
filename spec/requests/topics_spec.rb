require 'rails_helper'

RSpec.describe "Topics", type: :request do
  let(:topic) { create(:topic) }
  let(:other_topic) { create(:topic) }

  let!(:kept_article) { create(:article, topic: topic) }
  let!(:discarded_article) { create(:article, :discarded, topic: topic) }
  let!(:archived_article) { create(:article, :archived, topic: topic) }

  let!(:other_topic_article) { create(:article, topic: other_topic) }

  describe "GET /topics/:id (show)" do
    before do
      get topic_path(topic)
    end

    it "is successful" do
      expect(response).to be_successful
    end

    it "displays the correct topic's name" do
      expect_body_to_include(" Articles in: #{topic.slug}")
    end

    it "displays only kept articles belonging to the topic" do
      expect_body_to_include(kept_article.title)
    end

    it "does not display discarded articles belonging to the topic" do
      expect_body_not_to_include(discarded_article.title)
    end

    it "does not display archived articles belonging to the topic" do
      expect_body_not_to_include(archived_article.title)
    end

    it "does not display articles from other topics" do
      expect_body_not_to_include(other_topic_article.title)
    end
  end
end

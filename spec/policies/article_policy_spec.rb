require 'rails_helper'

RSpec.describe ArticlePolicy, type: :policy do
  let(:guest) { nil }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  let(:kept_article) { create(:article, user: user) }
  let(:discarded_article) { create(:article, :discarded, user: user) }
  let(:archived_article) { create(:article, :archived, user: user) }

  subject { described_class }

  describe "Scope" do
    subject { Pundit.policy_scope!(user, Article) }

    let!(:kept) { create(:article) }
    let!(:discarded) { create(:article, :discarded) }
    let!(:archived) { create(:article, :archived) }

    context "for a guest or regular user" do
      let(:user) { guest }

      it "returns only kept articles" do
        is_expected.to contain_exactly(kept)
      end
    end

    context "for an admin" do
      let(:user) { admin }

      it "returns kept and discarded articles, but not archived ones" do
        is_expected.to contain_exactly(kept, discarded)
      end
    end
  end

  permissions :show? do
    it "permits anyone to see a kept article" do
      expect(subject).to permit(guest, kept_article)
    end

    it "forbids guests and other users from seeing a discarded article" do
      expect(subject).not_to permit(guest, discarded_article)
      expect(subject).not_to permit(other_user, discarded_article)
    end

    it "permits the owner to see their own discarded article" do
      expect(subject).to permit(user, discarded_article)
    end

    it "permits an admin to see a discarded article" do
      expect(subject).to permit(admin, discarded_article)
    end
  end

  permissions :create?, :toggle_clap? do
    it "forbids guests" do
      expect(subject).not_to permit(guest)
    end

    it "permits any logged-in user" do
      expect(subject).to permit(user)
    end
  end

  permissions :update?, :destroy? do
    it "forbids guests" do
      expect(subject).not_to permit(guest, kept_article)
    end

    it "permits the owner of the article" do
      expect(subject).to permit(user, kept_article)
    end

    it "forbids another user" do
      expect(subject).not_to permit(other_user, kept_article)
    end

    it "forbids an admin" do
      expect(subject).not_to permit(admin, kept_article)
    end
  end

  permissions :hide?, :restore? do
    it "forbids guests" do
      expect(subject).not_to permit(guest, kept_article)
    end

    it "forbids the owner of the article" do
      expect(subject).not_to permit(user, kept_article)
    end

    it "forbids another user" do
      expect(subject).not_to permit(other_user, kept_article)
    end

    it "permits an admin" do
      expect(subject).to permit(admin, kept_article)
    end
  end
end

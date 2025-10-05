require 'rails_helper'

RSpec.describe CommentPolicy, type: :policy do
  let(:guest) { nil }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:editor) { create(:user, :editor) }
  let(:comment) { create(:comment, user: user) }

  subject { described_class }

  permissions :create? do
    it "forbids guests from creating comments" do
      expect(subject).not_to permit(guest)
    end

    it "permits any logged-in user to create comments" do
      expect(subject).to permit(user)
    end
  end

  permissions :update?, :edit?, :destroy? do
    it "forbids guests" do
      expect(subject).not_to permit(guest, comment)
    end

    it "permits the owner of the comment" do
      expect(subject).to permit(user, comment)
    end

    it "permits an editor (who is not the owner)" do
      expect(subject).to permit(editor, comment)
    end

    it "forbids another regular user (who is not the owner)" do
      expect(subject).not_to permit(other_user, comment)
    end
  end
end

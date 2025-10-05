require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:guest) { nil }
  let(:record_owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  subject { described_class }

  permissions :show? do
    it "permits anyone to see a profile" do
      expect(subject).to permit(guest, record_owner)
      expect(subject).to permit(other_user, record_owner)
    end
  end

  permissions :update? do
    it "forbids guests" do
      expect(subject).not_to permit(guest, record_owner)
    end

    it "permits the owner of the profile" do
      expect(subject).to permit(record_owner, record_owner)
    end

    it "permits an admin" do
      expect(subject).to permit(admin, record_owner)
    end

    it "forbids another regular user" do
      expect(subject).not_to permit(other_user, record_owner)
    end
  end

  permissions :destroy? do
    it "forbids guests" do
      expect(subject).not_to permit(guest, record_owner)
    end

    it "forbids the owner of the profile" do
      expect(subject).not_to permit(record_owner, record_owner)
    end

    it "forbids another regular user" do
      expect(subject).not_to permit(other_user, record_owner)
    end

    it "permits an admin" do
      expect(subject).to permit(admin, record_owner)
    end
  end
end

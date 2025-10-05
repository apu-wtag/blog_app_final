require 'rails_helper'

RSpec.describe ReportPolicy, type: :policy do
  let(:guest) { nil }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  let(:article_by_other_user) { create(:article, user: other_user) }
  let(:article_by_user) { create(:article, user: user) }

  let(:report_on_others_content) { Report.new(reportable: article_by_other_user) }
  let(:report_on_own_content) { Report.new(reportable: article_by_user) }

  subject { described_class }

  permissions :create? do
    it "forbids guests from creating a report" do
      expect(subject).not_to permit(guest, report_on_others_content)
    end

    it "permits a user to report another user's content" do
      expect(subject).to permit(user, report_on_others_content)
    end

    it "forbids a user from reporting their own content" do
      expect(subject).not_to permit(user, report_on_own_content)
    end
  end
end

class ReportPolicy < ApplicationPolicy
  def create?
    user.present? && record.reportable.user != user
  end
end

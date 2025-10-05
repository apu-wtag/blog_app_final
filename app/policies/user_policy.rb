class UserPolicy < ApplicationPolicy
  def show?
    true
  end
  def update?
    user.present? && (record == user || user.admin?)
  end
  def destroy?
    user.present? && user.admin?
  end
end

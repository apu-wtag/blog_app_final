class CommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end
  def update?
    user.present? && (user.editor? || record.user == user)
  end
  def edit?
    update?
  end
  def destroy?
    update?
  end
end

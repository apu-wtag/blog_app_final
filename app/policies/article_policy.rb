class ArticlePolicy < ApplicationPolicy
  def show?
    record.kept? || (user.present? && (user.admin? || record.user == user))
  end
  def create?
    user.present?
  end
  def update?
    user.present? && (record.user == user)
  end
  def destroy?
    update?
  end
  def hide?
    user.present? && user.admin?
  end
  def restore?
    hide?
  end
  def toggle_clap?
    user.present?
  end
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.with_discarded
      else
        scope.kept
      end

    end
  end
end

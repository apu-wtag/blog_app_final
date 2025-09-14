class ArticlePolicy < ApplicationPolicy
  def show?
    true
  end
  def create?
    user.present?
  end
  def update?
    user.present? && (record.user == user || user.admin?)
  end
  def destroy?
    update?
  end
  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

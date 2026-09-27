class TeamPolicy < ApplicationPolicy
  def show? = membership.present?
  def create? = user.present?
  def join? = membership.blank?
  def update? = membership&.admin?
  def import? = membership&.creator? || membership&.admin?

  class Scope < Scope
    def resolve
      scope.where(id: user.memberships.select(:team_id))
    end
  end

  private

  def membership
    Membership.find_by(user: user, team: record)
  end
end

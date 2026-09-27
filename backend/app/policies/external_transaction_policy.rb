class ExternalTransactionPolicy < ApplicationPolicy
  def show? = membership.present?
  def update? = membership&.creator? || membership&.admin?

  class Scope < Scope
    def resolve
      scope.where(team_id: user.memberships.select(:team_id))
    end
  end

  private

  def membership
    Membership.find_by(user: user, team: record.team)
  end
end
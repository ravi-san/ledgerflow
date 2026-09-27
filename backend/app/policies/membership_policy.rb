class MembershipPolicy < ApplicationPolicy
  def update? = admin_for_team? && !last_admin_demotion?
  def destroy? = admin_for_team? && !last_admin?

  private

  def admin_for_team?
    Membership.exists?(user: user, team: record.team, role: Membership.roles.fetch("admin"))
  end

  def last_admin?
    was_admin? && record.team.memberships.where(role: Membership.roles.fetch("admin")).count == 1
  end

  def last_admin_demotion?
    was_admin? && !record.admin? && last_admin?
  end

  def was_admin?
    record.role_in_database == "admin"
  end
end

class ExpensePolicy < ApplicationPolicy
  def index? = member?
  def show? = member?
  def create? = membership&.creator? || membership&.admin?
  def update? = (membership&.creator? || membership&.admin?) && !record.deleted_at?
  def destroy? = membership&.admin?
  def submit? = membership&.admin? || (membership&.creator? && record.member_id == user.id)
  def approve? = membership&.approver? || membership&.admin?
  def reject? = approve?
  def reimburse? = approve?
  def process_reimbursement? = approve?
  def pay_reimbursement? = membership&.admin?

  class Scope < Scope
    def resolve
      scope.where(team_id: user.memberships.select(:team_id))
    end
  end

  private
  def membership
    Membership.find_by(user: user, team: record.team)
  end
  def member? = membership.present?
end

class ReconcileLegacyLedgerflowSchema < ActiveRecord::Migration[7.1]
  CHECKS = {
    memberships: ["role IN (0, 1, 2, 3)", "memberships_role_valid"],
    expenses: ["status IN (0, 1, 2, 3, 4, 5)", "expenses_status_valid"],
    approval_steps: ["stage IN (0, 1)", "approval_steps_stage_valid"],
    reimbursements: ["status IN (0, 1, 2, 3)", "reimbursements_status_valid"],
    external_transactions: ["status IN (0, 1, 2)", "external_transactions_status_valid"]
  }.freeze

  def up
    change_column_null :users, :name, true if column_exists?(:users, :name)
    change_column_null :teams, :created_by_id, true if column_exists?(:teams, :created_by_id)
    change_column_null :approval_steps, :required_role, true if column_exists?(:approval_steps, :required_role)

    CHECKS.each do |table, (expression, name)|
      add_check_constraint table, expression, name: name unless check_constraint_exists?(table, name: name)
    end
  end

  def down
    CHECKS.each do |table, (_, name)|
      remove_check_constraint table, name: name if check_constraint_exists?(table, name: name)
    end
  end
end

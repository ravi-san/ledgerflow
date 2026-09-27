require "rails_helper"
require "support/records"

RSpec.describe ExpenseWorkflow do
  it "records manager and finance approval history before reimbursement is paid" do
    creator = user
    approver = user
    admin = user
    team = team()
    membership(user: creator, team: team, role: :creator)
    membership(user: approver, team: team, role: :approver)
    membership(user: admin, team: team, role: :admin)
    expense = expense(team: team, member: creator)

    described_class.new(expense: expense, actor: creator).call(action: :submit)
    described_class.new(expense: expense, actor: approver).call(action: :approve)
    described_class.new(expense: expense, actor: approver).call(action: :approve)
    described_class.new(expense: expense, actor: approver).call(action: :reimburse)
    described_class.new(expense: expense, actor: approver).call(action: :process_reimbursement)
    described_class.new(expense: expense, actor: admin).call(action: :pay_reimbursement)

    expect(expense.reload).to be_reimbursed
    expect(expense.approval_steps.order(:stage).pluck(:stage, :decision, :decided_by_id)).to eq([
      ["manager", "approved", approver.id],
      ["finance", "approved", approver.id]
    ])
    expect(expense.reimbursement).to be_paid
    expect(expense.audits.pluck(:action)).to include("submit", "approve", "reimburse", "process_reimbursement", "pay_reimbursement")
  end

  it "requires a rejection reason and rolls back the rejection" do
    creator = user
    approver = user
    team = team()
    expense = expense(team: team, member: creator)
    described_class.new(expense: expense, actor: creator).call(action: :submit)

    expect do
      described_class.new(expense: expense, actor: approver).call(action: :reject)
    end.to raise_error(ActiveRecord::RecordInvalid, /rejection reason is required/i)

    expect(expense.reload).to be_submitted
    expect(expense.approval_steps).to all(be_pending)
  end
end

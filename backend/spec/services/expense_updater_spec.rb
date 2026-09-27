require "rails_helper"
require "support/records"

RSpec.describe ExpenseUpdater do
  it "updates an expense and writes an audit diff in one transaction" do
    actor = user
    team = team()
    membership(user: actor, team: team, role: :creator)
    expense = expense(team: team, member: actor)

    updated = described_class.new(
      expense: expense,
      actor: actor,
      expected_version: expense.lock_version,
      attributes: { amount_cents: 2_000, description: "Team lunch" }
    ).call

    expect(updated.amount_cents).to eq(2_000)
    expect(updated.lock_version).to eq(1)
    expect(updated.audits.last.changeset).to include(
      "amount_cents" => { "old" => 1_250, "new" => 2_000 },
      "description" => { "old" => "Client lunch", "new" => "Team lunch" }
    )
  end

  it "rejects stale updates without overwriting the current version" do
    actor = user
    team = team()
    expense = expense(team: team, member: actor)

    described_class.new(expense: expense, actor: actor, expected_version: 0, attributes: { amount_cents: 1_500 }).call

    expect do
      described_class.new(expense: expense, actor: actor, expected_version: 0, attributes: { amount_cents: 9_999 }).call
    end.to raise_error(ExpenseUpdater::Conflict)

    expect(expense.reload.amount_cents).to eq(1_500)
  end

  it "rolls back the business update if the audit record cannot be written" do
    team = team()
    owner = user
    expense = expense(team: team, member: owner)

    expect do
      described_class.new(expense: expense, actor: nil, expected_version: expense.lock_version, attributes: { amount_cents: 3_000 }).call
    end.to raise_error(ActiveRecord::RecordInvalid)

    expect(expense.reload.amount_cents).to eq(1_250)
    expect(expense.audits.count).to eq(0)
  end
end

require "rails_helper"
require "support/records"

RSpec.describe ExpenseVersionComparer do
  it "reconstructs two snapshots and highlights only fields changed between them" do
    actor = user
    team = team()
    expense = expense(team: team, member: actor)
    created = expense.audits.create!(user: actor, action: "create", changeset: ExpenseAudit.diff_for_create(expense))

    expense = ExpenseUpdater.new(
      expense: expense,
      actor: actor,
      expected_version: expense.lock_version,
      attributes: { amount_cents: 2_000, description: "Updated lunch" }
    ).call
    updated = expense.audits.last

    comparison = described_class.new(expense: expense, from_audit: created, to_audit: updated).call

    expect(comparison[:changed_fields]).to contain_exactly("amount_cents", "description")
    expect(comparison[:changes]["amount_cents"]).to eq(old: 1_250, new: 2_000)
  end
end

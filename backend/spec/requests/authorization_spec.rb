require "rails_helper"
require "support/records"

RSpec.describe "Authorization", type: :request do
  it "prevents viewers from mutating expenses at the API layer" do
    viewer = user
    team = team()
    membership(user: viewer, team: team, role: :viewer)
    expense = expense(team: team, member: viewer)

    patch "/expenses/#{expense.id}", params: { amount_cents: 9_000, lock_version: expense.lock_version }, headers: bearer(viewer)

    expect(response).to have_http_status(:forbidden)
    expect(expense.reload.amount_cents).to eq(1_250)
  end

  it "returns 409 and the current record for stale API updates" do
    creator = user
    team = team()
    membership(user: creator, team: team, role: :creator)
    expense = expense(team: team, member: creator)

    ExpenseUpdater.new(expense: expense, actor: creator, expected_version: expense.lock_version, attributes: { amount_cents: 2_000 }).call
    patch "/expenses/#{expense.id}", params: { amount_cents: 9_000, lock_version: 0 }, headers: bearer(creator)

    expect(response).to have_http_status(:conflict)
    expect(JSON.parse(response.body)).to include("error" => "conflict")
    expect(expense.reload.amount_cents).to eq(2_000)
  end

  it "allows a creator to submit their own expense" do
    creator = user
    team = team()
    membership(user: creator, team: team, role: :creator)
    expense = expense(team: team, member: creator)

    post "/expenses/#{expense.id}/submit", headers: bearer(creator)

    expect(response).to have_http_status(:ok)
    expect(expense.reload).to be_submitted
  end

  it "allows a team member to view an expense audit trail" do
    creator = user
    team = team()
    membership(user: creator, team: team, role: :creator)
    expense = expense(team: team, member: creator)
    expense.audits.create!(
      user: creator,
      action: "create",
      changeset: ExpenseAudit.diff_for_create(expense)
    )

    get "/expenses/#{expense.id}/audit_trail", headers: bearer(creator)

    expect(response).to have_http_status(:ok)
    document = JSON.parse(response.body)
    audit = document.fetch("data").first
    expect(audit).to include("id" => expense.audits.first.id.to_s, "type" => "expense_audit")
    expect(audit.fetch("attributes")).to include("action" => "create", "occurred_at" => a_kind_of(String))
    expect(audit.fetch("attributes")).not_to include("expense_id", "user_id", "created_at", "updated_at")
    expect(audit.fetch("attributes").fetch("changeset")).not_to include("team_id", "member_id", "deleted_at", "lock_version")
    expect(document.fetch("included").first).to include("id" => creator.id.to_s, "type" => "user")
  end

  it "prevents a creator from submitting another member's expense" do
    creator = user
    other_creator = user
    team = team()
    membership(user: creator, team: team, role: :creator)
    membership(user: other_creator, team: team, role: :creator)
    expense = expense(team: team, member: other_creator)

    post "/expenses/#{expense.id}/submit", headers: bearer(creator)

    expect(response).to have_http_status(:forbidden)
    expect(expense.reload).to be_draft
  end

  it "limits marking reimbursements paid to admins" do
    approver = user
    team = team()
    membership(user: approver, team: team, role: :approver)
    expense = expense(team: team, member: approver, status: :approved)
    expense.create_reimbursement!(status: :requested)

    post "/expenses/#{expense.id}/pay_reimbursement", headers: bearer(approver)

    expect(response).to have_http_status(:forbidden)
    expect(expense.reimbursement.reload).to be_requested
  end
end

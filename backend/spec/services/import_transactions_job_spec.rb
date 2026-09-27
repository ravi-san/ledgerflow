require "rails_helper"
require "support/records"

RSpec.describe ImportTransactionsJob do
  it "is idempotent when Sidekiq retries the same payload" do
    team = team()
    rows = [
      {
        "external_id" => "bank-001",
        "amount_cents" => 4_200,
        "description" => "Bank card charge",
        "transacted_on" => "2026-09-25"
      }
    ]

    2.times { described_class.perform_now(team.id, rows) }

    expect(team.external_transactions.count).to eq(1)
    expect(team.external_transactions.first).to have_attributes(
      external_id: "bank-001",
      amount_cents: 4_200,
      status: "pending_review"
    )
  end
end

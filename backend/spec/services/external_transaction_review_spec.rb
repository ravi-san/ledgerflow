require "rails_helper"
require "support/records"

RSpec.describe ExternalTransactionReview do
  it "accepts a pending import once and creates an audited pending-review expense" do
    actor = user
    team = team()
    transaction = team.external_transactions.create!(
      external_id: "bank-002",
      amount_cents: 2_500,
      description: "Imported charge",
      transacted_on: Date.new(2026, 9, 25)
    )

    expense = described_class.new(transaction: transaction, actor: actor).accept!

    expect(expense).to be_pending_review
    expect(expense.audits.first.changeset.fetch("amount_cents")).to eq("old" => nil, "new" => 2_500)
    expect(transaction.reload).to be_accepted
    expect { described_class.new(transaction: transaction, actor: actor).accept! }.to raise_error(ExternalTransactionReview::AlreadyReviewed)
  end
end

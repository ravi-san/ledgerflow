class ImportTransactionsJob < ApplicationJob
  queue_as :default

  def perform(team_id, rows)
    team = Team.find(team_id)
    rows.each do |row|
      ExternalTransaction.insert_all(
        [{
          team_id: team.id,
          external_id: row.fetch("external_id"),
          amount_cents: row.fetch("amount_cents"),
          description: row.fetch("description"),
          transacted_on: row.fetch("transacted_on"),
          status: ExternalTransaction.statuses.fetch("pending_review")
        }],
        unique_by: :index_external_transactions_on_team_id_and_external_id
      )
    end
  end
end

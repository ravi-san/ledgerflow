class ExpenseAudit < ApplicationRecord
  after_commit :broadcast_change

  belongs_to :expense
  belongs_to :user
  validates :action, :changeset, presence: true

  AUDITED_EXPENSE_FIELDS = %w[
    team_id member_id amount_cents description spent_on category status lock_version deleted_at
  ].freeze
  API_HIDDEN_CHANGESET_FIELDS = %w[team_id member_id deleted_at lock_version].freeze

  def self.diff_for_create(expense)
    expense.attributes.slice(*AUDITED_EXPENSE_FIELDS).transform_values do |value|
      { "old" => nil, "new" => value }
    end
  end

  private

  def broadcast_change
    TeamBroadcaster.audit_changed(self)
  end
end

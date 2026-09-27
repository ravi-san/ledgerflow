class ExternalTransaction < ApplicationRecord
  belongs_to :team
  belongs_to :expense, optional: true
  enum :status, { pending_review: 0, accepted: 1, rejected: 2 }
  validates :external_id, presence: true, uniqueness: { scope: :team_id }
end

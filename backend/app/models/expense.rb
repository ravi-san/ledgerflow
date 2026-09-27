class Expense < ApplicationRecord
  after_commit :broadcast_change

  belongs_to :team
  belongs_to :member, class_name: "User"
  has_many :audits, class_name: "ExpenseAudit", dependent: :restrict_with_exception
  has_many :approval_steps, dependent: :destroy
  has_one :reimbursement, dependent: :destroy
  enum :status, { draft: 0, submitted: 1, approved: 2, reimbursed: 3, rejected: 4, pending_review: 5 }
  validates :lock_version, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :description, :spent_on, :category, presence: true

  private

  def broadcast_change
    TeamBroadcaster.expense_changed(self)
  end
end

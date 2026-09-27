class ExternalTransactionReview
  AlreadyReviewed = Class.new(StandardError)

  def initialize(transaction:, actor:)
    @transaction = transaction
    @actor = actor
  end

  def accept!
    ExternalTransaction.transaction do
      transaction = ExternalTransaction.lock.find(@transaction.id)
      raise AlreadyReviewed, "transaction has already been reviewed" unless transaction.pending_review?

      expense = transaction.team.expenses.create!(
        amount_cents: transaction.amount_cents,
        description: transaction.description,
        spent_on: transaction.transacted_on,
        category: "imported",
        member: @actor,
        status: :pending_review
      )
      expense.audits.create!(user: @actor, action: "create", changeset: ExpenseAudit.diff_for_create(expense))
      transaction.update!(status: :accepted, expense: expense)
      expense
    end
  end

  def reject!(reason:)
    ExternalTransaction.transaction do
      transaction = ExternalTransaction.lock.find(@transaction.id)
      raise AlreadyReviewed, "transaction has already been reviewed" unless transaction.pending_review?

      transaction.update!(status: :rejected, review_reason: reason)
    end
  end
end

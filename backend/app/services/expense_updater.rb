class ExpenseUpdater
  Conflict = Class.new(StandardError)

  def initialize(expense:, actor:, attributes:, expected_version:)
    @expense = expense
    @actor = actor
    @attributes = attributes
    @expected_version = expected_version.to_i
  end

  def call
    Expense.transaction do
      locked = Expense.lock.find(@expense.id)
      raise Conflict, "stale expense" unless locked.lock_version == @expected_version

      before = locked.attributes.slice("amount_cents", "description", "spent_on", "category", "status", "member_id")
      locked.assign_attributes(@attributes)
      locked.save!
      after = locked.attributes.slice(*before.keys)
      changeset = before.each_with_object({}) { |(key, old_value), diff| diff[key] = { "old" => old_value, "new" => after[key] } if old_value != after[key] }
      locked.audits.create!(user: @actor, action: "update", changeset: changeset)
      locked
    end
  rescue ActiveRecord::StaleObjectError
    raise Conflict, "stale expense"
  end
end

class TeamBroadcaster
  def self.expense_changed(expense)
    TeamChannel.broadcast_to(expense.team, {
      event: "expense.changed",
      expense_id: expense.id,
      lock_version: expense.lock_version
    })
  end

  def self.audit_changed(audit)
    TeamChannel.broadcast_to(audit.expense.team, {
      event: "audit.changed",
      expense_id: audit.expense_id,
      audit_id: audit.id
    })
  end
end

class ExpenseVersionComparer
  def initialize(expense:, from_audit:, to_audit:)
    @expense = expense
    @from_audit = from_audit
    @to_audit = to_audit
  end

  def call
    audits = @expense.audits.where(id: ..[@from_audit.id, @to_audit.id].max).order(:id)
    state = {}
    snapshots = {}

    audits.each do |audit|
      audit.changeset.each do |field, change|
        state[field] = change["new"]
      end
      snapshots[audit.id] = state.deep_dup if [@from_audit.id, @to_audit.id].include?(audit.id)
    end

    from_state = snapshots.fetch(@from_audit.id)
    to_state = snapshots.fetch(@to_audit.id)
    fields = (from_state.keys | to_state.keys).select { |field| from_state[field] != to_state[field] }

    {
      from_version: { audit_id: @from_audit.id, created_at: @from_audit.created_at, values: from_state },
      to_version: { audit_id: @to_audit.id, created_at: @to_audit.created_at, values: to_state },
      changed_fields: fields,
      changes: fields.index_with { |field| { old: from_state[field], new: to_state[field] } }
    }
  end
end

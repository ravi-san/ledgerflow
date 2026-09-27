class ExpenseAuditSerializer
  include JSONAPI::Serializer

  set_type :expense_audit

  attributes :action

  attribute :changeset do |audit|
    audit.changeset.except(*ExpenseAudit::API_HIDDEN_CHANGESET_FIELDS)
  end

  attribute :occurred_at do |audit|
    audit.created_at.iso8601
  end

  belongs_to :user, serializer: AuditActorSerializer
end

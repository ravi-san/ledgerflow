class ExpenseWorkflow
  def initialize(expense:, actor:)
    @expense = expense
    @actor = actor
  end

  def call(action:, reason: nil)
    Expense.transaction do
      puts "Processing action: #{action}"
      Rails.logger.info "0000000000 Processing action: #{action}"
      expense = Expense.lock.find(@expense.id)
      before_status = expense.status
      workflow_changes = {}
      case action.to_s
      when "submit"
        invalid!(expense, "expense is not draft or pending review") unless expense.draft? || expense.pending_review?

        expense.update!(status: :submitted)
        expense.approval_steps.find_or_create_by!(stage: ApprovalStep.stages.fetch("manager"))
        expense.approval_steps.find_or_create_by!(stage: ApprovalStep.stages.fetch("finance"))
      when "approve"
        membership = Membership.find_by(user: @actor, team: expense.team)
        raise Pundit::NotAuthorizedError unless membership&.approver? || membership&.admin?
        step = expense.approval_steps.where(decision: :pending).order(:stage).first
        invalid!(expense, "no pending approval") unless step
        step.update!(decision: :approved, decided_by: @actor, decided_at: Time.current)
        workflow_changes["approval_#{step.stage}"] = { "old" => "pending", "new" => "approved" }
        expense.update!(status: expense.approval_steps.where(decision: :pending).exists? ? :submitted : :approved)
      when "reject"
        invalid!(expense, "expense is not awaiting approval") unless expense.submitted?
        invalid!(expense, "rejection reason is required") if reason.blank?

        expense.update!(status: :rejected)
        step = expense.approval_steps.where(decision: :pending).order(:stage).first
        invalid!(expense, "no pending approval") unless step
        step.update!(decision: :rejected, decided_by: @actor, decided_at: Time.current, rejection_reason: reason)
        workflow_changes["approval_#{step.stage}"] = { "old" => "pending", "new" => "rejected" }
        workflow_changes["rejection_reason"] = { "old" => nil, "new" => reason }
      when "reimburse"
        invalid!(expense, "expense is not approved") unless expense.approved?
        invalid!(expense, "reimbursement already exists") if expense.reimbursement

        expense.create_reimbursement!(status: :requested)
      when "process_reimbursement"
        reimbursement = expense.reimbursement
        invalid!(expense, "reimbursement is not requested") unless reimbursement&.requested?
        reimbursement.update!(status: :processing)
      when "pay_reimbursement"
        reimbursement = expense.reimbursement
        invalid!(expense, "reimbursement is not processing") unless reimbursement&.processing?
        reimbursement.update!(status: :paid, paid_at: Time.current)
        expense.update!(status: :reimbursed)
      else
        raise ArgumentError, "unknown workflow action"
      end
      changeset = workflow_changes
      changeset["status"] = { "old" => before_status, "new" => expense.status } if before_status != expense.status
      changeset["reimbursement_status"] = reimbursement_change(action, expense)
      changeset.compact!
      expense.audits.create!(user: @actor, action: action.to_s, changeset: changeset)
      expense
    end
  end

  private

  def invalid!(record, message)
    record.errors.add(:base, message)
    raise ActiveRecord::RecordInvalid, record
  end

  def reimbursement_change(action, expense)
    case action.to_s
    when "reimburse" then { "old" => nil, "new" => "requested" }
    when "process_reimbursement" then { "old" => "requested", "new" => "processing" }
    when "pay_reimbursement" then { "old" => "processing", "new" => "paid" }
    end
  end
end

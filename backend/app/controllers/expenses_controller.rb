class ExpensesController < ApplicationController
  before_action :set_expense, only: [:show, :update, :destroy, :audit_trail, :compare, :submit, :approve, :reject, :reimburse, :process_reimbursement, :pay_reimbursement]

  def index
    team = current_user.teams.find(params[:team_id])
    authorize team, :show?
    expenses = policy_scope(team.expenses).includes(:member).where(deleted_at: nil).order(spent_on: :desc)
    render json: expenses.as_json(include: { member: { only: [:id, :email] } })
  end

  def show
    authorize @expense
    render json: @expense.as_json(include: {
      approval_steps: { include: { decided_by: { only: [:id, :email] } } },
      reimbursement: {}
    })
  end

  def create
    team = current_user.teams.find(params[:team_id])
    expense = team.expenses.new(expense_params.merge(member: current_user))
    authorize expense
    Expense.transaction do
      expense.save!
      expense.audits.create!(user: current_user, action: "create", changeset: ExpenseAudit.diff_for_create(expense))
    end
    render json: expense, status: :created
  end

  def update
    authorize @expense
    expense = ExpenseUpdater.new(expense: @expense, actor: current_user, attributes: expense_params, expected_version: params.require(:lock_version)).call
    render json: expense
  rescue ExpenseUpdater::Conflict => error
    render json: { error: "conflict", message: error.message, current: @expense.reload }, status: :conflict
  end

  def destroy
    authorize @expense
    Expense.transaction do
      before = @expense.deleted_at
      @expense.update!(deleted_at: Time.current)
      @expense.audits.create!(user: current_user, action: "delete", changeset: { "deleted_at" => { "old" => before, "new" => @expense.deleted_at } })
    end
    head :no_content
  end

  def audit_trail
    authorize @expense, :show?
    audits = @expense.audits.includes(:user).order(:created_at)
    render json: ExpenseAuditSerializer.new(audits, include: [:user]).serializable_hash
  end

  def compare
    authorize @expense, :show?
    from = @expense.audits.find(params.require(:from))
    to = @expense.audits.find(params.require(:to))
    render json: ExpenseVersionComparer.new(expense: @expense, from_audit: from, to_audit: to).call
  end

  %w[submit approve reject reimburse process_reimbursement pay_reimbursement].each do |action|
    define_method(action) do
      authorize @expense, "#{action}?"
      ExpenseWorkflow.new(expense: @expense, actor: current_user).call(action: action, reason: params[:reason])
      render json: @expense.reload
    end
  end

  private
  def set_expense 
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.permit(:amount_cents, :description, :spent_on, :category)
  end

end

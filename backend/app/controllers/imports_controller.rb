class ImportsController < ApplicationController
  before_action :set_transaction, only: [:show, :accept, :reject]

  def index
    team = current_user.teams.find(params[:team_id])
    authorize team, :show?
    render json: policy_scope(team.external_transactions).order(created_at: :desc)
  end

  def create
    team = current_user.teams.find(params[:team_id])
    authorize team, :import?
    rows = params.require(:rows).map do |row|
      row.permit(:external_id, :amount_cents, :description, :transacted_on).to_h
    end
    ImportTransactionsJob.perform_later(team.id, rows)
    render json: { status: "queued", team_id: team.id, rows: rows.length }, status: :accepted
  end

  def show
    authorize @transaction, :show?
    render json: @transaction
  end

  def accept
    authorize @transaction, :update?
    expense = ExternalTransactionReview.new(transaction: @transaction, actor: current_user).accept!
    render json: expense, status: :created
  rescue ExternalTransactionReview::AlreadyReviewed => error
    render json: { error: "unprocessable_entity", message: error.message }, status: :unprocessable_entity
  end

  def reject
    authorize @transaction, :update?
    ExternalTransactionReview.new(transaction: @transaction, actor: current_user).reject!(reason: params[:reason])
    render json: @transaction.reload
  rescue ExternalTransactionReview::AlreadyReviewed => error
    render json: { error: "unprocessable_entity", message: error.message }, status: :unprocessable_entity
  end

  def bulk_accept
    transactions = policy_scope(ExternalTransaction).where(id: params.require(:ids), status: :pending_review)
    transactions.each { |transaction| authorize transaction, :update? }
    expenses = transactions.map { |transaction| ExternalTransactionReview.new(transaction: transaction, actor: current_user).accept! }
    render json: expenses, status: :created
  end

  def bulk_reject
    transactions = policy_scope(ExternalTransaction).where(id: params.require(:ids), status: :pending_review)
    transactions.each { |transaction| authorize transaction, :update? }
    transactions.find_each { |transaction| ExternalTransactionReview.new(transaction: transaction, actor: current_user).reject!(reason: params[:reason]) }
    render json: transactions.reload
  end

  private

  def set_transaction
    @transaction = ExternalTransaction.find(params[:id])
  end
end

class ApplicationController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError do
    render json: { error: "forbidden" }, status: :forbidden
  end
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "not_found" }, status: :not_found
  end
  rescue_from ActionController::ParameterMissing do |error|
    render json: { error: "invalid_request", message: error.message }, status: :unprocessable_entity
  end
  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { error: "unprocessable_entity", message: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end
  rescue_from ActiveRecord::StaleObjectError do
    render json: { error: "conflict", message: "Expense changed since it was loaded" }, status: :conflict
  end

  private

  def current_user
    return @current_user if defined?(@current_user)
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    return nil if token.blank?

    payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256").first if token.present?
    @current_user = User.find(payload.fetch("user_id"))
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound, KeyError
    nil
  end

  def authenticate_user!
    render json: { error: "unauthorized" }, status: :unauthorized unless current_user
  end

  def pundit_user
    current_user
  end
end

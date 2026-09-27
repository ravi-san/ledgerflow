class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: :login
  skip_before_action :verify_authenticity_token, raise: false
  def login
    user = User.find_by(email: params.require(:email))
    return render json: { error: "invalid email or password" }, status: :unauthorized unless user&.authenticate(params.require(:password))
    render json: {
      token: JWT.encode({ user_id: user.id, exp: 24.hours.from_now.to_i }, Rails.application.secret_key_base, "HS256"),
      user: user.as_json(only: [:id, :email])
    }
  end
end

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_user
    end

    private

    def find_user
      token = request.headers["Authorization"]&.delete_prefix("Bearer ") || request.params["token"]
      payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256").first
      User.find(payload.fetch("user_id"))
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound, KeyError
      reject_unauthorized_connection
    end
  end
end

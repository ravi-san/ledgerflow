class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :team
  enum :role, { viewer: 0, creator: 1, approver: 2, admin: 3 }
  validates :user_id, uniqueness: { scope: :team_id }

  ROLE_LEVELS = { "viewer" => 0, "creator" => 1, "approver" => 2, "admin" => 3 }.freeze

  def at_least?(required_role)
    ROLE_LEVELS[role] >= ROLE_LEVELS[required_role.to_s]
  end
end

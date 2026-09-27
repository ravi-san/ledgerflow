class User < ApplicationRecord
  PASSWORD_FORMAT = /\A(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}\z/

  has_secure_password
  has_many :memberships, dependent: :destroy
  has_many :teams, through: :memberships
  has_many :expense_audits, dependent: :restrict_with_exception

  validates :email, presence: true, uniqueness: true
  validates :password,
            format: {
              with: PASSWORD_FORMAT,
              message: "must be at least 8 characters and include an uppercase letter, number, and special character"
            },
            allow_nil: true
end

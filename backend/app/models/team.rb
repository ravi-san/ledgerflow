class Team < ApplicationRecord
  has_secure_token :join_code, length: 24

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :expenses, dependent: :restrict_with_exception
  has_many :external_transactions, dependent: :destroy

  validates :name, :join_code, presence: true
  validates :join_code, uniqueness: true
  validates :name, length: { minimum: 2, maximum: 100 }, format: { with: /\A[a-zA-Z\s]+\z/, message: "only allows letters and spaces" }
end

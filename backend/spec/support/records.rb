module Records
  def user(email: "user-#{SecureRandom.hex(4)}@example.com", password: "Password@1")
    User.create!(email: email, password: password)
  end

  def team(name: "Team #{SecureRandom.hex(3).tr('0-9', 'a-j')}")
    Team.create!(name: name)
  end

  def membership(user:, team:, role:)
    Membership.create!(user: user, team: team, role: role)
  end

  def expense(team:, member:, amount_cents: 1_250, status: :draft)
    Expense.create!(
      team: team,
      member: member,
      amount_cents: amount_cents,
      description: "Client lunch",
      spent_on: Date.new(2026, 9, 25),
      category: "meals",
      status: status
    )
  end

  def bearer(user)
    token = JWT.encode({ user_id: user.id, exp: 1.hour.from_now.to_i }, Rails.application.secret_key_base, "HS256")
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include Records
end

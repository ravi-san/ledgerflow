admin = User.find_or_create_by!(email: "admin@example.com") { |user| user.password = "Admin@123" }
creator = User.find_or_create_by!(email: "creator@example.com") { |user| user.password = "Creator@123" }
approver = User.find_or_create_by!(email: "approver@example.com") { |user| user.password = "Approver@123" }
viewer = User.find_or_create_by!(email: "viewer@example.com") { |user| user.password = "Viewer@123" }

team = Team.find_or_create_by!(name: "Demo Team")

[
  [admin, :admin],
  [creator, :creator],
  [approver, :approver],
  [viewer, :viewer]
].each do |member, role|
  Membership.find_or_create_by!(user: member, team: team) { |membership| membership.role = role }
end

if team.expenses.none?
  expense = team.expenses.create!(
    member: creator,
    amount_cents: 8_750,
    description: "Client workshop supplies",
    spent_on: Date.current,
    category: "operations"
  )
  expense.audits.create!(user: creator, action: "create", changeset: ExpenseAudit.diff_for_create(expense))
end

puts "Demo users: admin@example.com, creator@example.com, approver@example.com, viewer@example.com"

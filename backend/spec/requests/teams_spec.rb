require "rails_helper"
require "support/records"

RSpec.describe "Teams", type: :request do
  it "creates a team with the creator as admin" do
    owner = user

    post "/teams", params: { name: "Ops" }, headers: bearer(owner)

    expect(response).to have_http_status(:created)
    team = Team.find(JSON.parse(response.body).fetch("id"))
    expect(team.memberships.find_by(user: owner)).to be_admin
    expect(team.join_code).to be_present
  end

  it "lets admins change roles but prevents demoting the last admin" do
    admin = user
    teammate = user
    team = team()
    admin_membership = membership(user: admin, team: team, role: :admin)
    teammate_membership = membership(user: teammate, team: team, role: :viewer)

    patch "/teams/#{team.id}/memberships/#{teammate_membership.id}", params: { role: "approver" }, headers: bearer(admin)
    expect(response).to have_http_status(:ok)
    expect(teammate_membership.reload).to be_approver

    patch "/teams/#{team.id}/memberships/#{admin_membership.id}", params: { role: "viewer" }, headers: bearer(admin)
    expect(response).to have_http_status(:forbidden)
    expect(admin_membership.reload).to be_admin
  end

  it "requires the team's join code before granting viewer access" do
    owner = user
    newcomer = user
    team = team()
    membership(user: owner, team: team, role: :admin)

    post "/teams/#{team.id}/join", params: { join_code: "wrong" }, headers: bearer(newcomer)
    expect(response).to have_http_status(:forbidden)
    expect(team.memberships.find_by(user: newcomer)).to be_nil

    post "/teams/#{team.id}/join", params: { join_code: team.join_code }, headers: bearer(newcomer)
    expect(response).to have_http_status(:created)
    expect(team.memberships.find_by(user: newcomer)).to be_viewer
  end

  it "returns a clear conflict when a member tries to join the same team again" do
    member = user
    team = team()
    membership(user: member, team: team, role: :viewer)

    post "/teams/#{team.id}/join", params: { join_code: team.join_code }, headers: bearer(member)

    expect(response).to have_http_status(:conflict)
    expect(JSON.parse(response.body)).to include("error" => "already_a_member")
  end
end

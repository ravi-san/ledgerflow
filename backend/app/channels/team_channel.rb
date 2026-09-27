class TeamChannel < ApplicationCable::Channel
  def subscribed
    team = Team.find(params[:team_id])
    reject unless current_user.memberships.exists?(team: team)
    stream_for team
  end
end

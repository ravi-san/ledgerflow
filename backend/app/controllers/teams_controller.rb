class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :update, :join]

  def index
    render json: policy_scope(Team).order(:name).map { |team| team_payload(team) }
  end

  def show
    authorize @team
    render json: team_payload(@team)
  end

  def create
    team = Team.new(team_params)
    authorize team

    Team.transaction do
      team.save!
      team.memberships.create!(user: current_user, role: :admin)
    end

    render json: team, status: :created
  end

  def update
    authorize @team
    @team.update!(team_params)
    render json: @team
  end

  def join
    if @team.memberships.exists?(user: current_user)
      return render json: { error: "already_a_member", message: "You have already joined this team" }, status: :conflict
    end

    authorize @team, :join?
    unless ActiveSupport::SecurityUtils.secure_compare(@team.join_code, params.require(:join_code).to_s)
      return render json: { error: "invalid_join_code" }, status: :forbidden
    end

    membership = @team.memberships.create!(user: current_user, role: :viewer)
    render json: membership, status: :created
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    params.permit(:name)
  end

  def team_payload(team)
    membership = team.memberships.find_by(user: current_user)
    payload = team.as_json(except: :join_code).merge("current_role" => membership&.role)
    payload["join_code"] = team.join_code if membership&.admin?
    payload
  end
end

class MembershipsController < ApplicationController
  before_action :set_team
  before_action :set_membership, only: [:update, :destroy]

  def index
    authorize @team, :update?
    render json: @team.memberships.includes(:user).order(:id).as_json(include: { user: { only: [:id, :email] } })
  end

  def update
    @membership.assign_attributes(membership_params)
    authorize @membership
    @membership.save!
    render json: @membership
  end

  def destroy
    authorize @membership
    @membership.destroy!
    head :no_content
  end

  private

  def set_team
    @team = Team.find(params[:team_id])
  end

  def set_membership
    @membership = @team.memberships.find(params[:id])
  end

  def membership_params
    params.permit(:role)
  end
end

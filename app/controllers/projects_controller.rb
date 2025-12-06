class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show ]

  def show
    @tasks = @project.tasks
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end
end

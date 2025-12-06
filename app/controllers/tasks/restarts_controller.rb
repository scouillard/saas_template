class Tasks::RestartsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task

  def create
    @task.restart!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to project_path(@task.project) }
    end
  end

  private

  def set_task
    @task = current_user.projects.joins(:tasks).find_by!(tasks: { id: params[:task_id] }).tasks.find(params[:task_id])
  end
end

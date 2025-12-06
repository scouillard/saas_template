require "rails_helper"

RSpec.describe "Tasks::Restarts", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:task) { create(:task, :completed, project: project) }

  before do
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  describe "POST /tasks/:task_id/restart" do
    context "when user owns the task" do
      it "restarts the task and responds with turbo stream" do
        post task_restart_path(task), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(task.reload.status).to eq("pending")
      end

      it "restarts the task and redirects to project for HTML requests" do
        post task_restart_path(task)

        expect(response).to redirect_to(project_path(project))
        expect(task.reload.status).to eq("pending")
      end
    end

    context "when user does not own the task" do
      let(:other_user) { create(:user) }
      let(:other_project) { create(:project, user: other_user) }
      let(:other_task) { create(:task, :completed, project: other_project) }

      it "returns not found" do
        post task_restart_path(other_task)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      before do
        delete destroy_user_session_path
      end

      it "redirects to sign in" do
        post task_restart_path(task)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

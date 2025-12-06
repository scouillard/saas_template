require "rails_helper"

RSpec.describe Project, type: :model do
  describe "associations" do
    it "has many tasks" do
      project = create(:project)
      task = create(:task, project: project)

      expect(project.tasks).to include(task)
    end
  end
end

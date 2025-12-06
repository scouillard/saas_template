require "rails_helper"

RSpec.describe Task, type: :model do
  describe "#restart!" do
    let(:task) { create(:task, :completed) }

    it "sets status to pending" do
      task.restart!

      expect(task.status).to eq("pending")
    end
  end
end

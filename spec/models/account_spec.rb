require "rails_helper"

RSpec.describe Account, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:memberships).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:memberships) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end
end

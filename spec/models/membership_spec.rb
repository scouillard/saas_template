require "rails_helper"

RSpec.describe Membership, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    subject { create(:membership) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:account_id) }
  end
end

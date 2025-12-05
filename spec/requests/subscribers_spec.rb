require "rails_helper"

RSpec.describe "Subscribers", type: :request do
  describe "GET /subscribe" do
    it "renders the waitlist page" do
      get subscribe_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("We're Almost Ready")
    end
  end

  describe "POST /subscribe" do
    context "with valid parameters" do
      let(:valid_params) { { subscriber: { email: "test@example.com" } } }

      it "creates a subscriber" do
        expect {
          post subscribe_path, params: valid_params
        }.to change(Subscriber, :count).by(1)
      end

      it "returns turbo stream with success message" do
        post subscribe_path, params: valid_params, as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Subscribed! Thank you.")
      end

      it "downcases the email" do
        post subscribe_path, params: { subscriber: { email: "TEST@EXAMPLE.COM" } }
        expect(Subscriber.last.email).to eq("test@example.com")
      end
    end

    context "with invalid parameters" do
      it "does not create a subscriber with invalid email" do
        expect {
          post subscribe_path, params: { subscriber: { email: "invalid" } }
        }.not_to change(Subscriber, :count)
      end

      it "does not create a subscriber with duplicate email" do
        Subscriber.create!(email: "test@example.com")
        expect {
          post subscribe_path, params: { subscriber: { email: "test@example.com" } }
        }.not_to change(Subscriber, :count)
      end

      it "renders the form with errors via turbo stream" do
        post subscribe_path, params: { subscriber: { email: "invalid" } }, as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("turbo-stream")
      end
    end
  end
end

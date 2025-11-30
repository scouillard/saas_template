require "rails_helper"

RSpec.describe "Contact", type: :request do
  describe "GET /contact" do
    it "renders the contact form" do
      get contact_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Contact Us")
    end
  end

  describe "POST /contact" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          contact_message: {
            name: "John Doe",
            email: "john@example.com",
            title: "Question about pricing",
            message: "I have a question about your pricing plans."
          }
        }
      end

      it "creates a contact message" do
        expect {
          post contact_path, params: valid_params
        }.to change(ContactMessage, :count).by(1)
      end

      it "redirects to root with a success notice" do
        post contact_path, params: valid_params
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Thanks!")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          contact_message: {
            name: "",
            email: "invalid-email",
            title: "",
            message: ""
          }
        }
      end

      it "does not create a contact message" do
        expect {
          post contact_path, params: invalid_params
        }.not_to change(ContactMessage, :count)
      end

      it "renders the form with errors" do
        post contact_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Please fix the following errors")
      end
    end
  end
end

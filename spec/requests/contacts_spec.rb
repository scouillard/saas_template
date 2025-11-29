require "rails_helper"

RSpec.describe "Contacts", type: :request do
  describe "GET /help" do
    it "renders the contact form" do
      get help_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Contact Us")
    end
  end

  describe "POST /help" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          contact_message: {
            name: "John Doe",
            email: "john@example.com",
            subject: "Test Subject",
            message: "This is a test message."
          }
        }
      end

      it "creates a new contact message" do
        expect { post help_path, params: valid_params }.to change(ContactMessage, :count).by(1)
      end

      it "redirects to root with success notice" do
        post help_path, params: valid_params

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Thanks! We'll get back to you soon.")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          contact_message: {
            name: "",
            email: "",
            subject: "",
            message: ""
          }
        }
      end

      it "does not create a contact message" do
        expect { post help_path, params: invalid_params }.not_to change(ContactMessage, :count)
      end

      it "re-renders the form with errors" do
        post help_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Please fix the following errors")
      end
    end

    context "with invalid email format" do
      let(:invalid_email_params) do
        {
          contact_message: {
            name: "John Doe",
            email: "invalid-email",
            subject: "Test Subject",
            message: "This is a test message."
          }
        }
      end

      it "does not create a contact message" do
        expect { post help_path, params: invalid_email_params }.not_to change(ContactMessage, :count)
      end

      it "re-renders the form with email error" do
        post help_path, params: invalid_email_params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end

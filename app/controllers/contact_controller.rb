class ContactController < ApplicationController
  # Strict limit for public endpoint (3 per 10 minutes)
  rate_limit to: 3, within: 10.minutes, only: :create

  def new
    @contact_message = ContactMessage.new
  end

  def create
    @contact_message = ContactMessage.new(contact_message_params)
    if @contact_message.save
      redirect_to root_path, notice: "Thanks! We'll get back to you soon."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :title, :message)
  end
end

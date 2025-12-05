class SubscribersController < ApplicationController
  def new
    @subscriber = Subscriber.new
  end

  def create
    @subscriber = Subscriber.new(subscriber_params)

    respond_to do |format|
      if @subscriber.save
        format.turbo_stream
        format.html { redirect_to subscribe_path, notice: "Subscribed! Thank you." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("subscribe_form", partial: "subscribers/form", locals: { subscriber: @subscriber }) }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def subscriber_params
    params.require(:subscriber).permit(:email)
  end
end

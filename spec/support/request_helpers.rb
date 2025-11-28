module RequestHelpers
  def sign_in_user(user = nil)
    user ||= create(:user, :with_account)
    sign_in user
    user
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end

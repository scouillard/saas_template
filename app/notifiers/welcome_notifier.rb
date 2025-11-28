class WelcomeNotifier < Noticed::Event
  notification_methods do
    def message
      t(".message")
    end

    def url
      root_path
    end
  end
end

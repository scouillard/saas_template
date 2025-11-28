module TeamsHelper
  def role_badge_class(role)
    case role.to_s
    when "owner"
      "bg-primary/10 text-primary border border-primary/20"
    when "admin"
      "bg-secondary/10 text-secondary border border-secondary/20"
    else
      "bg-base-300 text-base-500 border border-base-300"
    end
  end
end

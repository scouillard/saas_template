class AccountInvitationMailer < ApplicationMailer
  def invite_email(invitation)
    @invitation = invitation
    @inviter = invitation.inviter
    @account = invitation.account
    @accept_url = accept_invitation_url(token: invitation.token)

    mail(to: invitation.email, subject: "You've been invited to join #{@account.name}")
  end
end

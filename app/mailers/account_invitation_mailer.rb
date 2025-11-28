class AccountInvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @inviter = invitation.inviter
    @account = invitation.account
    @accept_url = accept_invitation_url(token: invitation.token)

    mail(
      to: invitation.email,
      subject: "#{@inviter.name || @inviter.email} invited you to join #{@account.name}"
    )
  end
end

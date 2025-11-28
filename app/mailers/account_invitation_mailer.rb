class AccountInvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @account = invitation.account
    @invited_by = invitation.invited_by
    @accept_url = accept_invitation_url(token: invitation.token)

    mail(
      to: invitation.email,
      subject: "You've been invited to join #{@account.name}"
    )
  end
end

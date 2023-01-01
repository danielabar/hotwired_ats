class ApplicantMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.applicant_mailer.contact.subject
  #
  def contact
    @greeting = "Hi"

    mail to: "to@example.org"
  end
end

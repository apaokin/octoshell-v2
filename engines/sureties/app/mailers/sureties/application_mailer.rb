module Sureties
  class ApplicationMailer < ActionMailer::Base
    default from: 'from@example.com'
    layout 'mailer'
    def surety_confirmed(surety_id)
      @surety = Sureties::Surety.find(surety_id)
      admin_emails = Core.user_class.superadmins.map(&:email)
      mail to: admin_emails, subject: t(".subject", number: @surety.id)
    end

    def surety_accepted(surety_id)
      @surety = Sureties::Surety.find(surety_id)
      @user = @surety.author
      mail to: @user.email, subject: t(".subject", number: @surety.id)
    end

    def surety_rejected(surety_id)
      @surety = Sureties::Surety.find(surety_id)
      @user = @surety.author
      mail to: @user.email, subject: t(".subject", number: @surety.id)
    end
  end
end

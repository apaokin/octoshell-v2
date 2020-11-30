module Sureties
  class MailerWorker
    include Sidekiq::Worker
    sidekiq_options retry: 2, queue: :core_mailer

    def perform(template, args)
      Sureties::Mailer.send(template, *args).deliver!
    end
  end
end

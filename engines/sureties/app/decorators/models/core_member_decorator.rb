Core::Member.class_eval do
  aasm(:project_access_state, :column => :project_access_state) do
    state :engaged   # принял приглашение (заполнил организации)
    state :unsured   # упомянут в ещё не активированном поручительстве

    event :accept_invitation do
      transitions :from => :invited, :to => :engaged
    end

    event :append_to_surety do
      transitions :from => :engaged, :to => :unsured
    end

    event :substract_from_surety do
      transitions :from => [:allowed, :unsured], :to => :engaged
    end

    event :activate do
      transitions :from => [:unsured, :suspended], :to => :allowed

      after do
        if aasm(:project_access_state).from_state==:unsured
          ::Core::MailerWorker.perform_async(:access_to_project_granted, id)
          if project.pending? && project.accesses.where(state: :opened).any?
            project.activate!
          end
        elsif aasm(:project_access_state).from_state == :suspended
          ::Core::MailerWorker.perform_async(:access_to_project_granted, id)
        end
      end
    end
  end
end

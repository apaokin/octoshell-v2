class CloudComputingPreview
  def prepared_to_deny
    ::CloudComputing::Mailer.prepared_to_deny(User.first.id, CloudComputing::Access.first.id)
  end

  def prepared_to_finish
    ::CloudComputing::Mailer.prepared_to_finish(User.first.id, CloudComputing::Access.first.id)
  end

  def vm_created
    ::CloudComputing::Mailer.vm_created(User.first.id, CloudComputing::Access.first.id)
  end


  def vm_error
    ::CloudComputing::Mailer.vm_error(User.first.id, CloudComputing::Item.first.id)
  end

  def request_refused
    ::CloudComputing::Mailer.request_refused(CloudComputing::Request.first.id)
  end




end

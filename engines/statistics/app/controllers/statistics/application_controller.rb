module Statistics
  class ApplicationController < ::ApplicationController
    before_action :require_login
    #ActionController::Base
    layout "layouts/statistics/admin"

    #before_action :authorize_admins, :journal_user

    #def authorize_admins
    #  authorize!(:access, :admin)
    #end
#
#    def journal_user
#      logger.info "JOURNAL: url=#{request.url}/#{request.method}; user_id=#{current_user ? current_user.id : 'none'}"
#    end
  end
end

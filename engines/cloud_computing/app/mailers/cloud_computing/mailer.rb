module CloudComputing
  class Mailer < ActionMailer::Base
    # helper ApplicationHelper
    # helper ::ApplicationHelper

    def prepared_to_deny(user_id, access_id)
      @access = CloudComputing::Access.find(access_id)
      @user = User.find(user_id)
      assign_msg_with_project
    end

    def prepared_to_finish(user_id, access_id)
      @access = CloudComputing::Access.find(access_id)
      @user = User.find(user_id)
      assign_msg_with_project
    end

    def vm_created(user_id, access_id)
      @access = CloudComputing::Access.find(access_id)
      @user = User.find(user_id)
      assign_msg_with_project
    end


    def request_refused(request_id)
      @request = CloudComputing::Request.find(request_id)
      @user = @request.created_by
      project = @request.for
      project_link = view_context.link_to project.title, core.project_url(project)
      request_link = view_context.link_to "##{@request.id}", request_url(@request)
      @msg = t('.msg', project_link: project_link, request_link: request_link).html_safe
      mail(to: @user.email, subject: t('.subject'),
           template_name: 'default')
    end

    def vm_error(user_id, item_id)
      @user = User.find(user_id)
      item_log_link = view_context.link_to item_id, api_logs_admin_item_url(item_id)
      @msg = t('.msg', item_log_link: item_log_link).html_safe
      mail(to: @user.email, subject: t('.subject'),
           template_name: 'default')
    end

    private

    def assign_msg_with_project
      project = @access.for
      project_link = view_context.link_to project.title, core.project_url(project)
      access_link = view_context.link_to "##{@access.id}", access_url(@access)
      @msg = t('.msg', project_link: project_link, access_link: access_link).html_safe
      mail(to: @user.email, subject: t('.subject'),
           template_name: 'default')
    end

  end
end

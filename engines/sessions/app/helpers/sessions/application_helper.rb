module Sessions
  module ApplicationHelper
    def session_user_submenu_items
      menu = Face::Menu.new
      menu.items.clear
      menu.add_item(Face::MenuItem.new({name: t("engine_submenu.reports"),
                                        url: sessions.reports_path,
                                        regexp: /reports/}))
      menu.add_item(Face::MenuItem.new({name: t("engine_submenu.surveys"),
                                        url: sessions.user_surveys_path,
                                        regexp: /surveys/}))
      menu.items
    end

    def report_points(access, method)
      result = access.send method
      return t('sessions.evaluate_helper.not_evaluated') unless result
      return t('sessions.evaluate_helper.without_mark') if result.zero?
      result
    end

    def session_state_label(session)
      case session.state_name
      when :pending then
        "warning"
      when :active then
        "success"
      else
        "danger"
      end
    end

    def report_status_label(report)
      case report.state_name
      when :can_not_be_submitted then
        :primary
      when :accepted, :assessing, :filling then
        :warning
      when :submitted, :assessed then
        :success
      else
        :danger
      end
    end
  end
end

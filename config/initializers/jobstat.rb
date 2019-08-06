module Jobstat
  extend Octoface
  octo_configure do
  end

end


Face::MyMenu.items_for(:user_submenu) do
  add_item(t("user_submenu.job_stat"), jobstat.account_summary_show_path,
           %r{^jobstat/account/summary})
  add_item(t("user_submenu.job_table"), jobstat.account_list_index_path,
           %r{^jobstat/account/list})

end

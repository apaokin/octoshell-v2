module Sureties
  extend Octoface
  octo_configure :sureties do
    add_ability(:manage, :sureties, 'superadmins')
    add_controller_ability(:manage, :sureties, 'admin/sureties')
    add_routes do
      mount Sureties::Engine, :at => "/sureties"
    end


    after_init do

      Face::MyMenu.items_for(:admin_submenu) do

        sureties_count = Sureties::Surety.where(state: :confirmed).count
        sureties_title = if sureties_count.zero?
                           t("admin_submenu.sureties")
                         else
                           t("admin_submenu.sureties_with_count.html", count: sureties_count).html_safe
                         end

         add_item_if_may('sureties', sureties_title,
                  sureties.admin_sureties_path,
                  'sureties/admin/sureties')


      end
    end
  end
end

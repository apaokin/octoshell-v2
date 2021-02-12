require "sureties/engine"
require "sureties/settings"
module Sureties
  ::Octoface::Hook.add_hook(:sureties, "core/admin/projects/sureties",
                            :core, :core_admin_projects_show)

  # Your code goes here...
end

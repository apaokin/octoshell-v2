require "cloud_computing/engine"
require "cloud_computing/settings" if defined?(Octoface)
require "cloud_computing/interface" if defined?(Octoface)
require "awesome_nested_set"
require 'xmlrpc/client'
require "cloud_computing/support_methods" if defined?(Octoface)


module CloudComputing
  ::Octoface::CodeHook.add_hook(:cloud_computing, :core, :not_active_project) do |project|
    access = Access.approved.find_by(for: project)
    next unless access

    access.prepare_to_deny!
  end
end

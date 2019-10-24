require 'octoface'
require 'octoface/octo_config'
Dir["lib/octoface/engines/*.rb"].each {|file| require file[4..-1] }
Octoface::OctoConfig.finalize!
Dir["lib/**/*.rb"].reject { |f| f['receive_emails'] }.each {|file| require file[4..-1] }
require "contexts/user_abilities"

module Core
  module JobFixing
    class CommonUtils
      YAML_PATH = 'config/job_fixing_info.yaml'.freeze
      class << self
        def get_config
          if File.exist?(YAML_PATH)
            YAML.load_file(YAML_PATH) || {}
          else
            {}
          end
        end

        def write_config(config)
          File.write(YAML_PATH, config.to_yaml)
        end

        def lock_name
          :job_fixer_service
        end

      end
    end
  end
end

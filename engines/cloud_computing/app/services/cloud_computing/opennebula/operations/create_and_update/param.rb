module CloudComputing
  module Opennebula
    module Operations
      class CreateAndUpdate
        class Param
          extend Forwardable

          def self.operation_class
            CreateAndUpdate
          end

          %i[gb_param_types numeric_types boolean_types all_param_types].each do |a|
            define_singleton_method(a) do
              operation_class.public_send(a)
            end
          end

          def initialize(hash)
            @hash = hash.clone
            prepare
            @new_vm = @hash['vm_id'] || false
          end

          def new_vm?
            @new_vm
          end

          def [](att)
            @hash[att]
          end

          def value(identity)
            (@hash[identity] || {})['value']
          end

          def []=(att, value)
            @hash[att] = value
          end

          def add_result_pos(key, action, success, message = nil, code = nil,  *_args)
            puts [message, code].inspect.red
            add_result(key: key, success: success, action: action,
                       message: message, code: code)
          end

          def add_result(key: nil, success:, message: nil,
                         code: nil, action: nil, value: nil)
            target = key ? @hash[key] : @hash
            target['messages'] << [success, action, message, code] if message && code
            target['value'] = value if value
            if target['success'].nil?
              target['success'] = success
            else
              target['success'] &&= success
            end
          end

          def prepare
            self.class.gb_param_types.each do |a|
              value = @hash[a]
              next unless value

              @hash[a] = (value.to_f * 1024).to_i if value
            end
            @hash['messages'] = []
            self.class.all_param_types.each do |type|
              value = @hash[type]
              next if value.nil?

              @hash[type] = {
                'value' => value,
                'success' => nil,
                'messages' => []
              }
            end
          end

          def back_for_octoshell
            new_hash = {}
            @hash.each do |key, value|
              new_hash[key] = value.clone
            end

            self.class.gb_param_types.each do |a|
              value = (new_hash[a] || {})['value']
              next if value.nil?

              new_hash[a]['value'] = (value.to_f / 1024)
            end
            new_hash
          end
        end
      end
    end
  end
end

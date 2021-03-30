module CloudComputing
  module Opennebula
    module Operations
      class CreateAndUpdate
        attr_reader :client

        def initialize(client)
          @client = client
          @results = []
        end

        def add_result(new_result)
          result = @results.detect do |old_result|
            old_result['item_id'] == new_result['item_id'] &&
              old_result['holder_id'] == new_result['holder_id']
          end

          if result
            merge(result, new_result)
          else
            @results << new_result
          end
        end

        # def add_action()
        #
        # end

        def merge(result, new_result)
          result['success'] &&= new_result['success']
          result['messages'] ||= []
          result['messages'] << new_result['messages']
          result.merge new_result
        end

        # def add_to_results
        #
        # end



        def to_value_string(hash, delim)

        end

        def create(attributes)
          return if attributes['vm_id']

          template_id = attributes['template_id']
          results = attributes.slice('item_id, holder_id')
          template_info_results = client.template_info(template_id)
          unless template_info_results[0]
            add_result(results.merge(
              'success' => false,
              'messages' => [template_info_results[0..2]]
            ))
            return
          end


          hash = {}
          hash['CONTEXT'] = Hash.from_xml(template_info_results[1])['VMTEMPLATE']['TEMPLATE']['CONTEXT'] || {}
          hash['CONTEXT']['SSH_PUBLIC_KEY'] =  attributes['public_keys']
          hash['USER'] = 'root'
          hash['OCTOSHELL_BOUND_TO_TEMPLATE'] = 'OCTOSHELL_BOUND_TO_TEMPLATE'

          value = attributes['MEMORY']

          if value
            hash['MEMORY'] = value.to_i
          end

          value = attributes['CPU']

          if value
            hash['CPU'] = value.to_i
            hash['VCPU'] = value.to_i
          end
          value_string = to_value_string(hash, "\n")

          # n_i = item.create_virtual_machine!(state: 'initial', last_info: DateTime.now)
          holder_id = attributes['holder_id']
          item_id = attributes['item_id']
          name = "octo-#{holder_id}-#{item_id}"
          instantiate_results = client.instantiate_vm(template_id, name, value_string)

          if instantiate_results[0]
            attributes['vm_id'] = instantiate_results[1]

            results = results.merge(
              'vm_id' => instantiate_results[1],
              'success' => true,
              'CPU' => [true, hash['CPU']],
              'MEMORY' => [true, hash['MEMORY']]
            )
            # n_i.update!(identity: results[1])
            # n_i.api_logs.create!(action: 'on_create', log: results, item: n_i.item)
          else
            results = results.merge(
              'success' => false,
              'messages' => [instantiate_results[0..2]]
            )
          end
          add_result(results)
        end

        def update(item)

        end

        def prepare_params(params)
          params.each do |param|
            %w[MEMORY DISK=>SIZE].each do |a|
              value = param[a]
              param[a] = (value.to_f * 1024).to_i.to_s if value
            end
          end
        end

        def finish
          @results.each do |result|
            %w[MEMORY DISK=>SIZE].each do |a|
              value = result[a]

              next unless value

              result[a][1] = (value[1].to_f / 1024).to_f.to_s
            end
          end
        end

        def execute(params)
          prepare_params(params)
          params.each do |item|
            create(item)
          end

          params.each do |item|
            update(item)
          end
          finish
          @results
        end
      end
    end
  end
end

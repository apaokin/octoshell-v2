module CloudComputing
  module Opennebula
    module Operations
      require 'main_spec_helper'
        describe CreateAndUpdate::Param do
          describe '#back_for_octoshell' do
            it 'forms valid hash' do
              param = CreateAndUpdate::Param.new(
                'item_id' => 5,
                'DISK=>SIZE' => 4.0,
                'CPU' => 4.0
              )
              expect(param.back_for_octoshell).to include(
                'item_id' => 5,
                'CPU' => {
                  'value' => 4.0,
                  'success' => nil,
                  'messages' => []
                },
                'DISK=>SIZE' => {
                  'value' => 4.0,
                  'success' => nil,
                  'messages' => []
                }
              )

              param.add_result_pos('DISK=>SIZE', 'RESIZE', false, 'message', 123)

              expect(param.back_for_octoshell).to include(
                'item_id' => 5,
                'CPU' => {
                  'value' => 4.0,
                  'success' => nil,
                  'messages' => []
                },
                'DISK=>SIZE' => {
                  'value' => 4.0,
                  'success' => false,
                  'messages' => [[false, 'message', 123]]
                }
              )

            end
          end
        end
    end
  end
end

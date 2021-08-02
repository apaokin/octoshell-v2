module CloudComputing
  module Admin
    module AccessesHelper
      def form_same_accesses(access)
        access.same_accesses.mergeable.map do |a|
          ["#{a.id} | #{a.human_state_name}", a.id]
        end
      end
    end
  end
end

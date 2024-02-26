module Jobstat
  class FormService
    # include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    attr_reader :q

    def query_constructor
      RunNodeService
    end

    def initialize(relation, params = {})
      @attrs = params.except(:q)
      @q = relation.ransack(
        { partition_eq: 'compute',
          submit_time_gteq: DateTime.new(2022, 1, 1).to_s,
          submit_time_lteq: DateTime.new(2023, 1, 1).to_s })
    end

    def call
      query_constructor.new(@q.result, 4, 3).call
    end

    def method_missing(name, *args, **kwargs)
      super unless query_constructor.valid? name

      @attrs[name]
    end
  end
end

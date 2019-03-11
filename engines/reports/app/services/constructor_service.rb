module Reports
  class ConstructorService

    WHERE = {
      all: {
        unary: ['IS NOT NULL', 'IS NULL']
      },
      %i[boolean] => {
        unary: %w[true false]
      },
      %i[integer] => {
        binary_operators: ['>', '=', '<', '>=', '<=']
      },
      %i[datetime date time] => {
        binary_operators: ['>', '=', '<', '>=', '<=']
      },
      %i[string text] => {
        binary_operators: ['=']
      }
    }.freeze

    # AGGREGATE = {
    #   %i[integer datetime] => %i[SUM MIN MAX AVG COUNT]
    # }.freeze


    def self.where
      all = WHERE[:all]
      arr = WHERE.map do |key, value|
        next if key == :all
        new_value_array = value.map do |key2, value2|
          [key2, value2 + (all[key2] || [])]
        end
        new_value = all.merge Hash[new_value_array]
        [key, new_value]
      end
      Hash[arr]
    end
    # attr_reader :join, :select

    def self.attributes_with_type(model)
      columns = model.columns_hash
      types = columns.map do |key, val|
        "#{key}|#{val.type}"
        # val.type
      end
      [columns.keys, types]
    end

    def self.class_info(array)
      cl = eval(array.first)
      array = array.drop(1)
      array.each do |elem|
        cl = cl.reflect_on_association(elem).klass
      end
      model_associations_with_type(cl) + attributes_with_type(cl)
    end

    def self.model_associations_with_type(model)
      reflections = model.reflections.values
      types = reflections.map do |r|
        type = r.macro
        "#{r.name}|#{type}"
      end
      enums = reflections.map do |r|
        r.name
      end
      [enums, types]
    end

    def value(hash)
      # array = value.sp
    end

    def put_select(hash)
      @in_select = []
      @attribute_names = []
      hash['attributes'].values.each do |v|
        value = v['value']
        if v['aggregate']
          attribute = "#{v['aggregate']}_#{value}"
          @attribute_names << attribute
          puts attribute
          @in_select << "#{v['aggregate']}(#{value}) AS #{attribute}"
        else
          puts value.inspect.blue
          @attribute_names << value
          @in_select << value
        end
      end
    end

    def put_order(hash)
      order_array = hash['attributes'].values.select do |v|
        v['order'] == 'ASC' || v['order'] == 'DESC'
      end.map { |v| [v['value'], v['order']] }
      @order = Hash[order_array]
    end

    def put_group(hash)
      @group = hash['attributes'].values.select do |v|
        v['order'] == 'GROUP'
      end.map { |v| v['value'] }
    end


    #Два случая: 1) лист оказался лефт, всё лефт. Есть  вершина с иннер, до неё ещё иннер 2) Если иннер джоин, всё иннер
    def deep_copy(o)
      Marshal.load(Marshal.dump(o))
    end





    def self.convert_left_to_inner(hash)
      hash.values.each do |value|
        convert_left_to_inner_assoc(value)
      end
    end

    def self.convert_left_to_inner_assoc(hash)
      res = false
      change_to_inner = false
      if hash['join_type'] == 'left'
        (hash.keys - ['join_type']).each do |key|
          change_to_inner ||= convert_left_to_inner_assoc(hash[key])
        end
      elsif hash['join_type'] == 'inner'
        res = true
      end

      if change_to_inner
        hash['join_type'] = 'inner'
        res = true
      end
      res
    end

    def split_joins(hash)
      @inner_join = {}
      @left_join = {}
      split_joins_inside(@inner_join, @left_join, hash)
    end

    def split_joins_inside(inner, left, hash)
      puts hash.inspect.red
      hash.each do |key, value|
        puts "#{key.inspect}->#{value.inspect}".green
        next if key == 'join_type'
        type = value['join_type']
        if type == 'inner' && inner
          inner[key.to_sym] = {}
        end
        left[key.to_sym] = {}
        puts inner.inspect.yellow
        puts left.inspect.yellow
        split_joins_inside(inner[key.to_sym], left[key.to_sym], value)
      end
    end

    def put_assocation(old_hash)
      return unless old_hash
      hash = deep_copy(old_hash)
      self.class.convert_left_to_inner(hash)
      split_joins(hash)
      puts @inner_join
      puts @left_join
    end

    # {a: :b, c: :e, d: {f: [:e,:g]}}


    def initialize(hash)
      @activerecord_class = eval(hash['class_name'])
      if hash['attributes']
        @inner_join = {}
        @left_join = {}
        put_select(hash)
        put_order(hash)
        put_group(hash)
        put_assocation(hash['association'])
      end
    end
    def to_a
      # puts @activerecord_class.select(*@in_select).order(@order).to_sql
      @activerecord_class.select(*@in_select).order(@order).group(@group)
                         .joins(@inner_join).left_join(@left_join)
                         .to_a.map do |e|
        Hash[@attribute_names.map do |s|
          [s.downcase, e[s.downcase]]
        end]
      end
    end

    def to_csv
      a = to_a

      CSV.generate do |csv|
        # csv << ["row", "of", "CSV", "data"]
        # csv << ["another", "row"]
        # ...
      end

      ([a[0].keys] + a.map(&:values)).to_csv
    end
  end
end

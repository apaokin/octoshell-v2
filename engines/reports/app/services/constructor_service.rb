module Reports
  class ConstructorService
    def self.attributes_with_type(model)
      columns = model.columns_hash
      types = columns.map do |key, val|
        "#{key}|#{val.type}"
        # val.type
      end
      [columns.keys, types]
    end

    def self.associations_with_type(array)
      cl = eval(array.first)
      array = array.drop(1)
      array.each do |elem|
        cl = cl.reflect_on_association(elem).klass
      end
      model_associations_with_type(cl)
    end

    def self.array_attributes_with_type(array)
      cl = eval(array.first)
      array = array.drop(1)
      array.each do |elem|
        cl = cl.reflect_on_association(elem).klass
      end
      attributes_with_type(cl)
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


  end
end

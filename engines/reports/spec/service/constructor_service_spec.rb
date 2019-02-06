module Reports
  require 'main_spec_helper'
  describe ConstructorService do
    it '#attributes_with_type' do
      attributes, types = ConstructorService.attributes_with_type(Core::Project)
      # puts attributes.inspect
      # puts types.inspect
    end

    it '#model_associations_with_type' do
      reflections, types = ConstructorService.model_associations_with_type(Core::Project)
      # puts reflections.inspect
      # puts types.inspect
    end

    it '#associations_with_type' do
      reflections, types = ConstructorService.assocs_attrs_with_type ['Core::Project','organization']
      puts reflections.inspect
      puts types.inspect
    end



  end
end

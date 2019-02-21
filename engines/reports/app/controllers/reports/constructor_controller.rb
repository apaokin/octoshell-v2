require_dependency "reports/application_controller"

module Reports
  class ConstructorController < ApplicationController
    def show
      @alpaca_raw_json = {
        class_options: ModelsList.to_a,
        class_labels: ModelsList.to_a_labels
      }

      # @models = Reports::ConstructorService.to_a_labels
    end

    def class_info
      assocs = params[:assocs]
      # ar_class = eval(name)
      # attributes, types = ConstructorService.attributes_with_type(ar_class)
      associations, associations_labels, attributes, types = ConstructorService.class_info(assocs)

      render json: { attributes: attributes, types: types,
                     associations: associations,
                     associations_labels: associations_labels }
    end

    # def nested_associations
    #   assocs = params[:assocs]
    #
    #   associations, associations_labels = ConstructorService.associations_with_type(assocs)
    #
    #   render json: { associations: associations,
    #                  associations_labels: associations_labels }
    # end
    #
    # def nested_attributes
    #   assocs = params[:assocs]
    #
    #   attributes, attributes_labels = ConstructorService.array_attributes_with_type(assocs)
    #
    #   render json: { attributes: attributes,
    #                  attributes_labels: attributes_labels }
    # end



  end
end

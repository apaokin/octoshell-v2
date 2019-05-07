require_dependency "reports/application_controller"

module Reports
  class ConstructorController < ApplicationController
    def show
      @alpaca_raw_json = {
        class_options: ModelsList.to_a,
        class_labels: ModelsList.to_a_labels,
        ops: ConstructorService.where
      }

      # @models = Reports::ConstructorService.to_a_labels
    end

    def class_info
      assocs = params[:assocs]
      # ar_class = eval(name)
      # attributes, types = ConstructorService.attributes_with_type(ar_class)
      associations, associations_labels, attributes, types = ConstructorService.class_info(assocs)
      table_name = eval(assocs.first).table_name
      render json: { attributes: attributes, types: types,
                     associations: associations,
                     associations_labels: associations_labels,
                     table_name: table_name}
    end

    def csv
      # send_data(your_data,
      #   :filename => "client-suggested-filename",
      #   :type => "mime/type")
      params.permit!
      @constructor = ConstructorService.new(params.to_h)
      # puts @constructor.to_csv
      # ConstructorService.new(params.to_h).to_csv
      # send_data @constructor.to_csv, filename: "users.csv", type: "mime/type"
      render json: { data: @constructor.to_csv }
    end

    def array
      params.permit!
      @constructor = ConstructorService.new(params.to_h)
      @constructor.count.to_f
      puts 'aaaa'
      pages = (@constructor.count.to_f / @constructor.per).ceil
      puts 'ffff'
      page ||= params[:page] || 1
      corrected_page = page.to_i > pages ? pages : page
      render json: { data: @constructor.to_2d_array, page: corrected_page,
                     pages: pages }
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

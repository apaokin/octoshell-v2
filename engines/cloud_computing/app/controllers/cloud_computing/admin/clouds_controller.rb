module CloudComputing::Admin
  class CloudsController < CloudComputing::Admin::ApplicationController
    helper CloudComputing::CloudsHelper
    def index
      @clouds = cloud_class.all
    end

    def show
      @cloud = cloud_class.find(params[:id])
    end

    def new
      @cloud = cloud_class.new
      fill_cloud_attributes
    end

    def create
      @cloud = cloud_class.new(cloud_params)
      if @cloud.save
        redirect_to [:admin, @cloud]
      else
        fill_cloud_attributes
        render :new
      end
    end

    def edit
      @cloud = cloud_class.find(params[:id])
      fill_cloud_attributes
    end

    def update
      @cloud = cloud_class.find(params[:id])
      if @cloud.update(cloud_params)
        redirect_to [:admin, @cloud]
      else
        fill_cloud_attributes
        render :edit
      end
    end

    private

    def fill_cloud_attributes
      @cloud.kind = 'Opennebula'
      @cloud.cloud_attributes.find_or_initialize_by(key: 'local_network_id')
      @cloud.cloud_attributes.find_or_initialize_by(key: 'internet_network_id')
    end


    def cloud_attribute_names
      %i[kind remote_host
         remote_private_key remote_port remote_path remote_user remote_password
         remote_command remote_proxy_host remote_proxy_port remote_use_ssl
         octo_password] + cloud_class.locale_columns(:name, :description)
    end

    def cloud_params
      params.require(:cloud)
            .permit(*cloud_attribute_names, cloud_attributes_attributes:
                                            %i[id key value _destroy])
    end

    def cloud_class
      CloudComputing::Cloud
    end
  end
end

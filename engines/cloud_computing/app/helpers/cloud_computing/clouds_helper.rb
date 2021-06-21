module CloudComputing
  module CloudsHelper
    def cloud_show_attrs(_cloud = nil)
      {
        %i[name description kind remote_host remote_port remote_path
           remote_proxy_host remote_proxy_port remote_use_ssl] => nil
      }
    end
  end
end

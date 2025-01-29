class Admin::OctoSettingsController < Admin::ApplicationController

  def index
    @octo_settings = OctoSetting.all.group_by(&:kind)
  end

  def new
    @octo_setting = OctoSetting.new(settings_params)
  end


  def create
    @octo_setting = OctoSetting.new(settings_params)
    if @octo_setting.save
      redirect_to admin_octo_settings_path
    else
      render 'new'
    end
  end

  def edit
    @octo_setting = OctoSetting.find params[:id]
  end

  def update
    @octo_setting = OctoSetting.find params[:id]
    if @octo_setting.update(settings_params)
      redirect_to admin_octo_settings_path
    else
      render 'edit'
    end
  end

  def destroy
    OctoSetting.find(params[:id]).destroy!
    redirect_to admin_octo_settings_path
  end


  private

  def settings_params
    params.require(:octo_setting)
          .permit(*%i[kind], *OctoSetting.locale_columns(:value), :active)
  end

  def options
    attributes = %i[value file_name]
    I18n.available_locales.map do |l|
      attributes.map { |a| :"#{a}_#{l}" }
    end.flatten
  end


end

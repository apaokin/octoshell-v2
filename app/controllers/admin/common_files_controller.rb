class Admin::CommonFilesController < Admin::ApplicationController
  def index
    @common_files = CommonFile.all
    without_pagination(:common_files)
  end

  def new
    @common_file = CommonFile.new
  end

  def create
    @common_file = CommonFile.new(common_file_params)
    if @common_file.save
      redirect_to admin_common_files_path
    else
      render 'new'
    end
  end

  def edit
    @common_file = CommonFile.find params[:id]
  end

  def update
    @common_file = CommonFile.find params[:id]
    if @common_file.update(common_file_params)
      redirect_to admin_common_files_path
    else
      render 'edit'
    end
  end

  def destroy
    CommonFile.find(params[:id]).destroy!
    redirect_to admin_common_files_path
  end

  private

  def common_file_params
    params.require(:common_file)
          .permit(:file, :description)
  end


end

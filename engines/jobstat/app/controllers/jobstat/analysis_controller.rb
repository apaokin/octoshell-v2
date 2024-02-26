require_dependency "jobstat/application_controller"

module Jobstat
  class AnalysisController < ApplicationController
    def main
      @form = FormService.new(Jobstat::Job.where(login: ''), params)
      @records = @form.call
      pp @records
    end
  end
end

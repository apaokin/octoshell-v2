module Octoface
  # This class can be as a superclass for classes defining bootstrap form helpers.
  # See child classes BootstrapFormHelper in other engines for better understanding.     
  class BootstrapFormHelper
    attr_reader :name, :options, :html_options, :f, :prefix
    def initialize(view, f, *args)
      if args.first.is_a?(String)
        @prefix, @options, @html_options = *args
      else
        @prefix = ''
        @options, @html_options = *args
      end
      @options ||= {}
      @html_options ||= {}

      @f = f
      @view = view
    end

    def method_missing(name, *args, &block)
      return @view.send(name, *args, &block) if @view.respond_to?(name)

      super
    end
  end
end

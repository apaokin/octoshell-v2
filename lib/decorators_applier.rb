class DecoratorReg
  def self.register!
    return if @set

    if (::ActiveRecord::Base.connection_pool.with_connection(&:active?) rescue false) &&
        ActiveRecord::Base.connection.data_source_exists?('users')
      Decorators.register! Rails.root, Core::Engine.root, Pack::Engine.root,
                           Sessions::Engine.root, Support::Engine.root
      @set = true
    end
  end

  def self.register_and_load!
    return if @set

    register!
    Decorators.load!(Rails.application.config.cache_classes)
  end
end
DecoratorReg.register!

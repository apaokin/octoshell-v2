module Octoface
  class OctoConfig
    attr_reader :abilities, :mod, :controller_abilities, :routes_block,
                :classes, :role, :ability_blocks
    def initialize(mod, role, &block)
      @mod = mod
      @role = role
      @abilities = []
      @ability_blocks = []
      @controller_abilities = []
      if self.class.instances[role]
        raise "You are trying to redefine #{role} role"
      end
      @classes = {}

      self.class.instances[role] = self
      # @settings = block
      # yield(self) if block_given?
      instance_eval(&block)
      @mod.define_singleton_method(:links) do
        @@links ||= []
      end

      @mod.define_singleton_method(:add_link) do |name|
        links << name
      end

      @mod.define_singleton_method(:link?) do |name|
        links.include?(name)
      end
    end

    # Gets constant for linked engine
    # @param class_name [String] Class_name without engine name
    def get_klass(class_name)
      mod.const_get(class_name)
    end

    def finish_intialization
      instance_eval(&@init_block) if @init_block
      return if %w[FakeMainApp Octoface].include? mod.to_s

      app_helper = eval("#{mod}::ApplicationHelper")
      ::ApplicationHelper.include app_helper
    end
    # "Allow" the class to be referenced directly outside engine
    # @param class_name [String] Class_name without engine name
    def add(name)
      @classes[name] = []
      # self.class.mod_methods[name] = obj
      # mod.define_singleton_method(name, &obj)

    end

    # Octoshell uses cancancan gem as an authorization tool. Permissions
    # are assigned in the Ability class (app/models/ability.rb) using can method.
    # There are 2 ways to handle permissions in Octoshell:
    # * Store permissions and edit them in browser (recommended).
    #   Use action, subject and groups arguments to create
    #   these permissions automically if they haven't yet.
    # * Use blocks to access Ability class directly (check out Support engine
    #   for detailed example)
    #
    # @example DB way
    #   add_ability(:manage, :projects, 'superadmins')
    #   can?(:manage, :projects) => true # If user is in "superadmins" group
    #
    # @example Block way
    #  can :manage, :projects if User.superadmins.include? user
    # @example Block way (Core::Project.accessible_by and other cancancan features can be used)
    #  can :manage, Core::Project if User.superadmins.include? user
    # @param action [Symbol] first argument of can method
    # @param subject [Symbol] second argument of can method
    # @param *groups [Array<String>] Allow these groups to do action on subject by default
    # @yield Block to be evaluated by Ability class
    #   (if these permsissions have not been created yet)
    def add_ability(action = nil, subject = nil, *groups, &block)
      @abilities << ([action, subject] + groups) if action && subject
      @ability_blocks << block if block
    end

    # call authorize!(action, subject) in the controllers specifed by paths arguments before action
    # @param action [Symbol] first argument of can method
    # @param subject [Symbol] second argument of can method
    # @param *paths [Array<String>] paths of controllers
    def add_controller_ability(action, subject, *paths)
      @controller_abilities << [action, subject] + paths
    end

    # The method adds engine routes
    # @yield Block to be evaluated inside config/routes.rb
    def add_routes(&block)
      @routes_block = block
    end


    # Executes code block after all initializers are loaded. The method is
    # used to add engine links
    # @yield Block to be executed
    def after_init(&block)
      @init_block = block
    end

    # Evaluate code block inside Interface class of the role if it is present
    # in the system
    def set(role, &block)
      config = self.class.instances[role]
      return unless config

      config.mod.const_get(:Interface).instance_eval(&block)
    end

    class << self

      def find_by_role(role)
        instances[role]
      end
      # Checks if role and class pair exists
      # @param role [Symbol]
      # @param class_name [String]

      def role_class?(role, class_name)
        role = find_by_role(role)
        return false unless role
        return false unless role.classes.keys.include?(class_name)

        true
      end

      def role_class(role, class_name)
        return nil unless role_class?(role, class_name)

        find_by_role(role).get_klass(class_name)
      end

      def mod_class_string(role, class_name)
        return class_name if role == :main_app

        "#{find_by_role(role).mod}::#{class_name}"
      end


      def action_and_subject_by_path(path)
        mod = path.split('/').first
        inside_engine_path = path.split('/')[1..-1].join('/')
        found_instance = instances.values.detect do |instance|
          mod_string = instance.mod.to_s.underscore
          mod_string == mod
        end

        unless found_instance
          found_instance = instances.values.detect do |instance|
            mod_string = instance.mod.to_s.underscore
            mod_string == 'fake_main_app'
          end
          inside_engine_path = path
        end
        found_instance.controller_abilities.detect { |ab| ab[2..-1].include?(inside_engine_path)}[0..1]

      end

      # def self.mods
      #   @mods ||= []
      # end

      def mod_methods
        @mod_methods ||= {}
      end

      def instances
        @instances ||= {}
      end

      def create_abilities!
        instances.values.each do |instance|
          instance.abilities.each do |a|
            Group.all.each do |g|
              Permission.where(action: a[0], subject_class: a[1], group_id: g.id).first_or_create do |ability|
                ability.available = a[2..-1].include?(g.name)
              end
            end
          end
        end
      end


      # executes @init_blocks
      def finalize!
        instances.values.each(&:finish_intialization)
        # create_abilities!
      end
    end


  end
end

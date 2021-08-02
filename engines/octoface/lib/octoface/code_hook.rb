module Octoface
  class CodeHook
    attr_reader :name
    def initialize(role, name)
      @name = name
      role_hooks = self.class.instances[role] ||= {}

      if role_hooks[name]
        raise "You are trying to redefine #{name} hook in #{role}"
      end
      role_hooks[name] = self
    end

    def blocks
      @blocks ||= {}
    end

    def add_block(from_role, &block)
      role_blocks = blocks[from_role] ||= []
      role_blocks << block
    end

    def eval_blocks(object)
      blocks.each_value do |procs|
        procs.each do |proc|
          proc.call(object)
        end
      end
    end

    class << self
      def instances
        @instances ||= {}
      end

      def add_hook(from_role, to_role, name, &block)
        find_or_initialize_hook(to_role, name).add_block(from_role, &block)
      end

      def register_place(role, name, object)
        find_or_initialize_hook(role, name).eval_blocks(object)
      end

      def find_or_initialize_hook(role, name)
        instances[role] && instances[role][name] ||
          new(role, name)
      end

    end
  end
end

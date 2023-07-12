module Rolify
  module Permission
    extend Utils

    # def self.included(base)
    #   base.extend Finders
    # end

    def add_permission(permission_name, resource = nil)
      permission = self.class.permission_adapter.find_or_create_by(
        permission_name.to_s,
        (resource.is_a?(Class) ? resource.to_s : resource.class.name if resource),
        (resource.id if resource && !resource.is_a?(Class))
      )

      unless permissions.include?(permission)
        self.class.define_dynamic_method(permission_name, resource) if Rolify.dynamic_shortcuts
        self.class.permission_adapter.add(self, permission)
      end

      permission
    end

    def has_permission?(permission_name, resource = nil)
      return has_strict_permission?(permission_name, resource) if self.class.strict_rolify and resource and resource != :any

      if new_record?
        permission_array = self.permissions.detect { |r|
          r.name.to_s == permission_name.to_s &&
            (r.resource == resource ||
             resource.nil? ||
             (resource == :any && r.resource.present?))
        }
      else
        permission_array = self.class.permission_adapter.where(self.permissions, name: permission_name, resource: resource)
      end

      return false if permission_array.nil?
      permission_array != []
    end

    def has_permission_via_roles?(permission_name, resource = nil)
      roles_with_permission = self.roles.includes(:permissions).where(permissions: { name: permission_name, resource: resource }).exists?
      roles_with_permission.present?
    end

    def has_strict_permission?(permission_name, resource)
      self.class.permission_adapter.where_strict(self.permissions, name: permission_name, resource: resource).any?
    end

    def has_cached_permission?(permission_name, resource = nil)
      return has_strict_cached_permission?(permission_name, resource) if self.class.strict_rolify and resource and resource != :any
      self.class.permission_adapter.find_cached(self.permissions, name: permission_name, resource: resource).any?
    end

    def has_strict_cached_permission?(permission_name, resource = nil)
      self.class.permission_adapter.find_cached_strict(self.permissions, name: permission_name, resource: resource).any?
    end

    def has_all_permissions?(*args)
      args.each do |arg|
        if arg.is_a? Hash
          return false unless self.has_permission?(arg[:name], arg[:resource])
        elsif arg.is_a?(String) || arg.is_a?(Symbol)
          return false unless self.has_permission?(arg)
        else
          raise ArgumentError, "Invalid argument type: only hash or string or symbol allowed"
        end
      end
      true
    end

    def has_any_permission?(*args)
      if new_record?
        args.any? { |r| self.has_permission?(r) }
      else
        self.class.permission_adapter.where(self.permissions, *args).size > 0
      end
    end

    def only_has_permission?(permission_name, resource = nil)
      self.has_permission?(permission_name,resource) && self.permissions.count == 1
    end

    def remove_permission(permission_name, resource = nil)
      self.class.permission_adapter.remove(self, permission_name.to_s, resource)
    end

    alias_method :revoke, :remove_permission
    deprecate :has_no_permission, :remove_permission

    def permissions_name
      self.permissions.pluck(:name)
    end

    def method_missing(method, *args, &block)
      if method.to_s.match(/^is_(\w+)_of[?]$/) || method.to_s.match(/^is_(\w+)[?]$/)
        resource = args.first
        self.class.define_dynamic_method $1, resource
        return has_permission?("#{$1}", resource)
      end if Rolify.dynamic_shortcuts
      super
    end

    def respond_to?(method, include_private = false)
      if Rolify.dynamic_shortcuts && (method.to_s.match(/^is_(\w+)_of[?]$/) || method.to_s.match(/^is_(\w+)[?]$/))
        query = self.class.permission_class.where(:name => $1)
        query = self.class.permission_adapter.exists?(query, :resource_type) if method.to_s.match(/^is_(\w+)_of[?]$/)
        return true if query.count > 0
        false
      else
        super
      end
    end
  end
end

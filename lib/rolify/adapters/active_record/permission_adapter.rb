require 'rolify/adapters/base'

module Rolify
  module Adapters
    module ActiveRecord
      class PermissionAdapter < Rolify::Adapters::PermissionAdapterBase
        def where(relation, *args)
          conditions, values = build_conditions(relation, args)
          relation.where(conditions, *values)
        end

        def where_strict(relation, args)
          wrap_conditions = relation.name != permission_class.name

          conditions = if args[:resource].is_a?(Class)
                         {:resource_type => args[:resource].to_s, :resource_id => nil }
                       elsif args[:resource].present?
                         {:resource_type => args[:resource].class.name, :resource_id => args[:resource].id}
                       else
                         {}
                       end

          conditions.merge!(:name => args[:name])
          conditions = wrap_conditions ? { permission_table => conditions } : conditions

          relation.where(conditions)
        end

        def find_cached(relation, args)
          resource_id = (args[:resource].nil? || args[:resource].is_a?(Class) || args[:resource] == :any) ? nil : args[:resource].id
          resource_type = args[:resource].is_a?(Class) ? args[:resource].to_s : args[:resource].class.name

          return relation.find_all { |permission| permission.name == args[:name].to_s } if args[:resource] == :any

          relation.find_all do |permission|
            (permission.name == args[:name].to_s && permission.resource_type == nil && permission.resource_id == nil) ||
              (permission.name == args[:name].to_s && permission.resource_type == resource_type && permission.resource_id == nil) ||
              (permission.name == args[:name].to_s && permission.resource_type == resource_type && permission.resource_id == resource_id)
          end
        end

        def find_cached_strict(relation, args)
          resource_id = (args[:resource].nil? || args[:resource].is_a?(Class)) ? nil : args[:resource].id
          resource_type = args[:resource].is_a?(Class) ? args[:resource].to_s : args[:resource].class.name

          relation.find_all do |permission|
            permission.resource_id == resource_id && permission.resource_type == resource_type && permission.name == args[:name].to_s
          end
        end

        def find_or_create_by(permission_name, resource_type = nil, resource_id = nil)
          permission_class.where(:name => permission_name, :resource_type => resource_type, :resource_id => resource_id).first_or_create
        end

        def add(relation, permission)
          relation.permissions << permission unless relation.permissions.include?(permission)
        end

        def remove(relation, permission_name, resource = nil)
          cond = { :name => permission_name }
          cond[:resource_type] = (resource.is_a?(Class) ? resource.to_s : resource.class.name) if resource
          cond[:resource_id] = resource.id if resource && !resource.is_a?(Class)
          permissions = relation.permissions.where(cond)
          if permissions
            relation.permissions.delete(permissions)
            permissions.each do |permission|
              permission.destroy if permission.send(ActiveSupport::Inflector.demodulize(user_class).tableize.to_sym).limit(1).empty?
            end if Rolify.remove_permission_if_empty
          end
          permissions
        end

        def exists?(relation, column)
          relation.where("#{column} IS NOT NULL")
        end

        def scope(relation, conditions, strict)
          query = relation.joins(:permissions)
          query = strict ? where_strict(query, conditions) : where(query, conditions)
          query
        end

        def all_except(user, excluded_obj)
          user.where.not(user.primary_key => excluded_obj)
        end

        private

        def build_conditions(relation, args)
          conditions = []
          values = []
          args.each do |arg|
            if arg.is_a? Hash
              a, v = build_query(arg[:name], arg[:resource])
            elsif arg.is_a?(String) || arg.is_a?(Symbol)
              a, v = build_query(arg.to_s)
            else
              raise ArgumentError, "Invalid argument type: only hash or string or a symbol allowed"
            end
            conditions << a
            values += v
          end
          conditions = conditions.join(' OR ')
          [ conditions, values ]
        end

        def build_query(permission, resource = nil)
          return [ "#{permission_table}.name = ?", [ permission ] ] if resource == :any
          query = "((#{permission_table}.name = ?) AND (#{permission_table}.resource_type IS NULL) AND (#{permission_table}.resource_id IS NULL))"
          values = [ permission ]
          if resource
            query.insert(0, "(")
            query += " OR ((#{permission_table}.name = ?) AND (#{permission_table}.resource_type = ?) AND (#{permission_table}.resource_id IS NULL))"
            values << permission << (resource.is_a?(Class) ? resource.to_s : resource.class.name)
            if !resource.is_a? Class
              query += " OR ((#{permission_table}.name = ?) AND (#{permission_table}.resource_type = ?) AND (#{permission_table}.resource_id = ?))"
              values << permission << resource.class.name << resource.id
            end
            query += ")"
          end
          [ query, values ]
        end
      end
    end
  end
end

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.setup

module Rolify
  extend Configure

  attr_accessor :strict_rolify, :resource_adapter
  attr_accessor :role_cname, :role_adapter, :role_join_table, :role_table_name
  attr_accessor :permission_cname, :permission_adapter, :permission_join_table, :permission_table_name

  @@resource_types = []

  def rolify(options = {})
    include Role
    extend Dynamic if Rolify.dynamic_shortcuts

    self.role_cname = options.fetch(:role_cname, 'Role')
    self.role_table_name = self.role_cname.tableize.gsub(/\//, "_")
    self.role_join_table = options.fetch(:join_table, default_join_table(role_table_name))

    rolify_options = { class_name: role_cname.camelize }
    rolify_options.merge!({ join_table: role_join_table }) if Rolify.orm == :active_record
    rolify_options.merge!(options.slice(:before_add, :after_add, :before_remove, :after_remove, :inverse_of))

    has_and_belongs_to_many :roles, **rolify_options

    self.role_adapter = Rolify::Adapters::Base.create("role_adapter", role_cname, name, permission_cname)

    #use strict roles
    self.strict_rolify = true if options[:strict]
  end

  def permify(options = {})
    include Permission

    self.permission_cname = options.fetch(:permission_cname, "Permission")
    self.permission_table_name = self.permission_cname.tableize.gsub(/\//, "_")
    self.permission_join_table = options.fetch(:join_table, default_join_table(permission_table_name))

    permify_options = { class_name: permission_cname.camelize }
    permify_options.merge!({ join_table: permission_join_table }) if Rolify.orm == :active_record
    permify_options.merge!(options.slice(:before_add, :after_add, :before_remove, :after_remove, :inverse_of))

    has_and_belongs_to_many :permissions, **permify_options

    self.role_adapter.permission_cname = permission_cname
    self.permission_adapter = Rolify::Adapters::Base.create("permission_adapter", role_cname, name, permission_cname)
  end

  def resourcify(role_table = :roles, permission_table = :permissions, options = {})
    include Resource

    self.role_cname = options.fetch(:role_cname, "Role")
    self.role_table_name = self.role_cname.tableize.gsub(/\//, '_')
    self.permission_cname = options.fetch(:permission_cname, "Permission")
    self.permission_table_name = self.permission_cname.tableize.gsub(/\//, '_')

    has_many role_table, class_name: self.role_cname.camelize, as: :resource, dependent: options.fetch(:dependent, :destroy)
    has_many permission_table, class_name: self.permission_cname.camelize, as: :resource, dependent: options.fetch(:dependent, :destroy)

    self.resource_adapter = Rolify::Adapters::Base.create("resource_adapter", role_cname, name, permission_cname)
    @@resource_types << name
  end

  def resource_adapter
    return self.superclass.resource_adapter unless instance_variable_defined? '@resource_adapter'
    @resource_adapter
  end

  def role_adapter
    return self.superclass.role_adapter unless self.instance_variable_defined? '@role_adapter'
    @role_adapter
  end

  def permission_adapter
    return self.superclass.permission_adapter unless self.instance_variable_defined? '@permission_adapter'
    @permission_adapter
  end

  def scopify
    extend Rolify::Adapters::ActiveRecord::Scopes
  end

  def role_class
    return self.superclass.role_class unless instance_variable_defined? '@role_cname'
    self.role_cname.constantize
  end

  def permission_class
    return self.superclass.permission_class unless instance_variable_defined? '@permission_cname'
    self.permission_cname.constantize
  end

  def self.resource_types
    @@resource_types
  end

  private

  def default_join_table(association)
    "#{self.to_s.tableize.gsub(/\//, "_")}_#{association}"
  end
end

loader.eager_load

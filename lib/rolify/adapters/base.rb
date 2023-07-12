module Rolify
  module Adapters
    class Base
      attr_accessor :role_cname, :permission_cname, :user_cname

      def initialize(role_cname, user_cname, permission_cname)
        @role_cname = role_cname
        @user_cname = user_cname
        @permission_cname = permission_cname
      end

      def role_class
        @role_cname.constantize
      end

      def permission_class
        @permission_cname.constantize
      end
      
      def user_class
        @user_cname.constantize
      end
      
      def role_table
        role_class.table_name
      end

      def permission_table
        permission_class.table_name
      end
      
      def self.create(adapter, role_cname, user_cname, permission_cname)
        if Rolify.orm == :active_record
          Rolify::Adapters::ActiveRecord.const_get(adapter.camelize.to_sym).new(role_cname, user_cname, permission_cname)
        else
          Rolify::Adapters::Mongoid.const_get(adapter.camelize.to_sym).new(role_cname, user_cname, permission_cname)
        end
      end

      def relation_types_for(relation)
        relation.descendants.map(&:to_s).push(relation.to_s)
      end
    end
  end
end

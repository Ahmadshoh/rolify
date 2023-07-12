module Rolify
	module Adapters
		class RoleAdapterBase < Rolify::Adapters::Base
			def initialize(role_cname, user_cname, permission_cname)
				super(role_cname, user_cname, permission_cname)
			end

			def where(relation, args)
				raise NotImplementedError.new("You must implement where")
			end

			def find_or_create_by(role_name, resource_type = nil, resource_id = nil)
				raise NotImplementedError.new("You must implement find_or_create_by")
			end

			def add(relation, role_name, resource = nil)
				raise NotImplementedError.new("You must implement add")
			end

			def remove(relation, role_name, resource = nil)
				raise NotImplementedError.new("You must implement delete")
			end

			def exists?(relation, column)
				raise NotImplementedError.new("You must implement exists?")
			end
		end
	end
end

module Rolify
	module Adapters
		class PermissionAdapterBase < Rolify::Adapters::Base
			def where(relation, args)
				raise NotImplementedError.new("You must implement where")
			end

			def find_or_create_by(permission_name, resource_type = nil, resource_id = nil)
				raise NotImplementedError.new("You must implement find_or_create_by")
			end

			def add(relation, permission_name, resource = nil)
				raise NotImplementedError.new("You must implement add")
			end

			def remove(relation, permission_name, resource = nil)
				raise NotImplementedError.new("You must implement delete")
			end

			def exists?(relation, column)
				raise NotImplementedError.new("You must implement exists?")
			end
		end
	end
end

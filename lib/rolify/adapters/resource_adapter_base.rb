module Rolify
	module Adapters
		class ResourceAdapterBase < Rolify::Adapters::Base
			def resources_find(roles_table, relation, role_name)
				raise NotImplementedError.new("You must implement resources_find")
			end

			def in(resources, roles)
				raise NotImplementedError.new("You must implement in")
			end
		end
	end
end

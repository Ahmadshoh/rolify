class RolifyCreate<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table(:roles) do |t|
      t.string :name
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:permissions) do |t|
      t.string :name
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:users_roles, :id => false) do |t|
      t.references :user
      t.references :role
    end

    create_table(:users_permissions, :id => false) do |t|
      t.references :user
      t.references :permission
    end

    create_table(:roles_permissions, :id => false) do |t|
      t.references :role
      t.references :permission
    end

    add_index(:roles, [ :name, :resource_type, :resource_id ])
    add_index(:permissions, [ :name, :resource_type, :resource_id ])
    add_index(:users_roles, [ :user_id, :role_id ])
    add_index(:users_permissions, [ :user_id, :permission_id ])
    add_index(:roles_permissions, [ :role_id, :permission_id ])
  end
end

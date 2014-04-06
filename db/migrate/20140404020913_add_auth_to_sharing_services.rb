class AddAuthToSharingServices < ActiveRecord::Migration
  def change
    add_column :sharing_services, :sharing_type, :text, default: 'custom'
    add_column :sharing_services, :service_id, :text
    add_column :sharing_services, :access_token, :text
    add_column :sharing_services, :access_secret, :text
  end
end

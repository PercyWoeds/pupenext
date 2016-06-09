class AddCampaignColumnToDiscounts < ActiveRecord::Migration
  def change
    add_column :hinnasto,       :kampanja, :integer, limit: 4, default: 0, null: false, after: :yhtion_toimipaikka_id
    add_column :asiakashinta,   :kampanja, :integer, limit: 4, default: 0, null: false, after: :piiri
    add_column :asiakasalennus, :kampanja, :integer, limit: 4, default: 0, null: false, after: :piiri
  end
end

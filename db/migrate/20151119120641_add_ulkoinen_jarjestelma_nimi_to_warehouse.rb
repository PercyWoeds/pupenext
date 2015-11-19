class AddUlkoinenJarjestelmaNimiToWarehouse < ActiveRecord::Migration
  def up
    add_column :varastopaikat, :ulkoinen_jarjestelma_nimi, :string, default: '', null: false, after: :ulkoinen_jarjestelma
  end

  def down
    remove_column :varastopaikat, :ulkoinen_jarjestelma_nimi
  end
end

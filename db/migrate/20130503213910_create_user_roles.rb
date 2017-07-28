# frozen_string_literal: true
class CreateUserRoles < ActiveRecord::Migration
  def change
    create_table :user_roles do |t|
      t.string :role, null: false, default: ''
      t.string :users, null: false, default: ''
      t.timestamps
    end
    add_index :user_roles, :role
    
    # default users in roles as of May 3, 2013
    UserRole.create(role: 'administrators',users: 'bess,geisler,hfrost,jdeering,lmcrae,petucket,snydman,tcramer,tonyn,jvine')
    UserRole.create(role: 'collection_creators',users: 'archivist1,archivist2,amyhodge,ronbo,mmarosti,dhartwig,skota,jcueva,gertvd,amorgan2,jejohns1,ssussman,jlmcbrid,jmanton,mtashiro')
    UserRole.create(role: 'global_viewers',users: 'ctierney,makeller,mcalter,mchris,rns,zbaker')
  end
end

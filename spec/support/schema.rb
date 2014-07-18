ActiveRecord::Schema.define(:version => 20130628161227) do

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "state",                                 :default => 'pending'
    t.boolean  "activated",                             :default => true
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.datetime "semiactivated_state_at"
    t.datetime "activated_state_at"
  end

  create_table "animals", :force => true do |t|
    t.string   "name"
    t.string   "status",                                :default => 'unborn'
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.datetime "status_changed_at"
    t.datetime "unborn_status_at"
    t.datetime "born_status_at"
  end

  create_table "zoos", :force => true do |t|
    t.string   "name"
    t.string   "state",                                 :default => 'closed'
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  create_table "farms", :force => true do |t|
    t.string   "name"
    t.string   "state",                                 :default => 'dirty'
    t.string   "house_state",                           :default => 'dirty'
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  create_table "factories", :force => true do |t|
    t.string "name"
    t.string "state"
  end

end

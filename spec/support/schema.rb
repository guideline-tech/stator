ActiveRecord::Schema.define(:version => 20130628161227) do

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "state"
    t.boolean  "activated",                             :default => true
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.datetime "semiactivated_state_at"
    t.datetime "activated_state_at"
  end

  create_table "animals", :force => true do |t|
    t.string   "name"
    t.string   "status"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.datetime "unborn_status_at"
    t.datetime "born_status_at"
  end

  create_table "zoos", :force => true do |t|
    t.string   "name"
    t.string   "state"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

end

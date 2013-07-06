ActiveRecord::Schema.define(:version => 20130628161227) do

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "state"
    t.boolean  "activated",                             :default => true
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  create_table "animals", :force => true do |t|
    t.string   "name"
    t.string   "status"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

end

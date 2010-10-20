# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101020074529) do

  create_table "facebook_users", :force => true do |t|
    t.integer  "user_id"
    t.string   "facebook_id"
    t.string   "name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "link"
    t.string   "email"
    t.integer  "timezone"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "financials", :force => true do |t|
    t.integer  "user_id"
    t.integer  "gross_income",                                   :null => false
    t.integer  "net_income",                                     :null => false
    t.integer  "total_expenses",                                 :null => false
    t.integer  "mortage_payment",                 :default => 0
    t.integer  "car_loan_payment",                :default => 0
    t.integer  "student_loan_payment",            :default => 0
    t.integer  "other_loan_payment",              :default => 0
    t.integer  "deferred_loan_amount",            :default => 0
    t.integer  "cc_debt",                         :default => 0
    t.integer  "cc_interest_rate",                :default => 0
    t.integer  "liquid_assets",                   :default => 0
    t.integer  "investments",                     :default => 0
    t.integer  "retirement_savings",              :default => 0
    t.integer  "monthly_retirement_contribution", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "financials", ["user_id"], :name => "index_financials_on_user_id"

  create_table "notifications", :force => true do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questions", :force => true do |t|
    t.integer  "financial_id"
    t.integer  "user_id"
    t.string   "item_name",                               :null => false
    t.integer  "item_cost",                               :null => false
    t.integer  "reason_to_buy",                           :null => false
    t.integer  "recurring_item_cost",  :default => 0
    t.integer  "age",                                     :null => false
    t.string   "nick_name",                               :null => false
    t.text     "expert_details"
    t.boolean  "expert_verdict"
    t.boolean  "pm_saving"
    t.boolean  "pm_investment"
    t.boolean  "pm_financing"
    t.integer  "pm_saving_amount",     :default => 0
    t.integer  "pm_investment_amount", :default => 0
    t.integer  "pm_financing_amount",  :default => 0
    t.boolean  "tos",                  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "questions", ["financial_id"], :name => "index_questions_on_financial_id"
  add_index "questions", ["user_id"], :name => "index_questions_on_user_id"

  create_table "responses", :force => true do |t|
    t.boolean  "verdict"
    t.text     "reason"
    t.integer  "question_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "responses", ["question_id"], :name => "index_responses_on_question_id"
  add_index "responses", ["user_id"], :name => "index_responses_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["username"], :name => "index_users_on_username"

end

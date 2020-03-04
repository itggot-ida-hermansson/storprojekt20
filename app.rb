require 'sinatra'
require 'slim'
require 'sqlite3'

get('/') do
    slim(:index)
end

post('/login') do
    userId=params[:user]
    pwd=params[:pass]

    db = SQLite3::Database.new("db/hej.db")
    db.results_as_hash = true
    user = db.execute("SELECT * FROM user where userid=?", userId)
    allUser = db.execute("SELECT * FROM user")
    slim(:start, locals:{user:user,users:allUser})
  end


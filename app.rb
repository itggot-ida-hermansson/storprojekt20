require 'sinatra'
require 'slim'
require 'sqlite3'


def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

   
get('/') do
    slim(:index,locals:{user:'',users:[], message:'Användarnamn'})
end



post('/login') do
    userId=params[:user]
    pwd=params[:pass]

    db = connect_to_db("db/hej.db")

    user = db.execute("SELECT * FROM user where userid=?", userId)
    if user == nil or user.length() == 0
        slim(:index,locals:{user:'',users:[], message:'Fel användare eller passord'})
    else  
        allUser = db.execute("SELECT * FROM user where userid!=?", userId)
        slim(:start, locals:{user:user.first,users:allUser})
    end    
  end


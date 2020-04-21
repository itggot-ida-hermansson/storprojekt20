require 'sinatra'
require 'slim'
require 'sqlite3'


def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end
   
get('/') do
    slim(:index,locals:{user:'',users:[], message:'Användarnamn', showGrid:false})
end

enable :sessions
post('/login') do
    userId=params[:user]
    pwd=params[:pass]
    db = connect_to_db("db/hej.db")
    userResult = db.query("SELECT * FROM user where userid=?", userId)
    if userResult
        user = userResult.next
        if user
            session[:hejUser] = user['id']
            allUser = db.execute("SELECT * FROM user where userid!=?", userId)    
            slim(:start, locals:{user:user,users:allUser, showGrid:true})
        else
            slim(:index,locals:{user:'',users:[], message:'Fel användare eller passord'})    
        end
    else
        slim(:index,locals:{user:'',users:[], message:'Fel användare eller passord'})    
    end    
end

get('/createAccount') do 
    slim(:account,locals:{user:'',users:[], message:'', showGrid:false})
end 

post('/user/add') do
    userId=params[:userid]
    pwd=params[:pass]
    name=params[:name]
    country=params[:country]
    address1=params[:address1]
    address2=params[:address2]

 #   db = connect_to_db("db/hej.db")
 db = SQLite3::Database.open("db/hej.db")
 db.results_as_hash = true
    result = db.query("SELECT MAX(id) as id FROM user;")
    first_result = result.next
    id=first_result['id'];
    id=id+1;  
    db.execute("INSERT INTO user('id', 'userid', 'name', 'country', 'pass', 'adress1', 'adress2') VALUES (?,?,?,?,?,?,?);", id,name,userId,pwd,country,address1,address2);
    slim(:index,locals:{user:'',users:[], message:'Användarnamn', showGrid:false})
end 

enable :sessions
get('/editAccount') do 
    id = session[:hejUser]
    db = connect_to_db("db/hej.db")
    userResult = db.query("SELECT * FROM user WHERE id=?", id)
    user = userResult.next
    if user
        slim(:editAccount,locals:{user:user,users:[], message:'', showGrid:false})
    end
end





require 'sinatra'
require 'slim'
require 'sqlite3'


def connect_to_db(path)
    db = SQLite3::Database.open(path)
    db.results_as_hash = true
    return db
end
   
get('/') do
    slim(:index,locals:{user:'',users:[], message:'', showGrid:false})
end

enable :sessions
post('/login') do
    userId=params[:user]
    pwd=params[:pass]
    db = connect_to_db("db/hej.db")
    userResult = db.execute("SELECT * FROM user where userid=?", userId)
    if userResult
        user = userResult[0]
        if user
            if pwd != user['pass']
                slim(:index,locals:{user:'',users:[], showGrid:false, message:'Fel användare eller passord'})   
            else
                session[:hejUser] = user['id']
                allUser = db.execute("SELECT * FROM user where userid!=?", userId)    
                slim(:start, locals:{user:user,users:allUser, showGrid:true, message:''})
            end 
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
    adress1=params[:adress1]
    adress2=params[:adress2]

    db = connect_to_db("db/hej.db")
    result = db.execute("SELECT MAX(id) as id FROM user;")
    first_result = result[0]
    id=first_result['id'];
    id=id+1;  
    db.execute("INSERT INTO user('id', 'userid', 'name', 'country', 'pass', 'adress1', 'adress2') VALUES (?,?,?,?,?,?,?);", id,name,userId,pwd,country,adress1,adress2);
    slim(:index,locals:{user:'',users:[], message:'Användarnamn', showGrid:false})
end 

enable :sessions
get('/editAccount') do 
    id = session[:hejUser]
    db = connect_to_db("db/hej.db")
    userResult = db.execute("SELECT * FROM user WHERE id=?", id)
    user = userResult[0]
    if user
        slim(:editAccount,locals:{user:user,users:[], message:'', showGrid:false})
    end
end

enable :sessions
post('/user/save') do
    id = session[:hejUser]
    pwd=params[:pass]
    userId=params[:userid]
    name=params[:name]
    country=params[:country]
    adress1=params[:adress1]
    adress2=params[:adress2]

    db = connect_to_db("db/hej.db")
    db.execute("UPDATE user set userid=?, name=?, country=?, pass=?, adress1=?, adress2=? WHERE id=?;", userId,name,country,pwd,adress1,adress2,id);
    allUsers = db.execute("SELECT * FROM user where userid!=?", userId)   
    userResult = db.execute("SELECT * FROM user WHERE id=?", id)
    user = userResult[0] 
    slim(:start,locals:{user:user,users:allUsers, message:'', showGrid:true})
end 



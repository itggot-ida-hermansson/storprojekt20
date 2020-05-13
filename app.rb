require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'


def connect_to_db(path)
    db = SQLite3::Database.open(path)
    db.results_as_hash = true
    return db
end

def showChatWindow(chat)
 
    db = SQLite3::Database.open("db/hej.db")
    db.results_as_hash = true
  
    userResult = db.execute("SELECT * FROM user where id=?;", chat['user1'])
    user = userResult[0]
  
    friendResult = db.execute("SELECT * FROM user where id=?;", chat['user2'])
    friend = friendResult[0]
    friend = friendResult[0]  
    friendId = friend['id']
  
    allUsers = db.query("SELECT * FROM user;")
    
    puts chat['id']
    messageResult = db.execute("SELECT m.* FROM message m join chat c on m.chat=c.id where c.id=?;",chat['id'])
    puts messageResult.length()
    for i in 1..messageResult.length() do
      puts messageResult[i]
    end
    
    slim(:"chat/start", locals:{user:user,chat:chat,friend:friend,users:allUsers, messages:messageResult, showGrid:true})
  
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
    if userResult.empty?
        slim(:index,locals:{user:'',users:[], message:'Hittar inte användare',showGrid:false}) 
    else 
        user = userResult[0]
        password_digest = BCrypt::Password.new (user["pass"])

        if password_digest != pwd
            slim(:index,locals:{user:'',users:[], showGrid:false, message:'Felaktigt passord'})   
        else
            session[:hejUser] = user['id']
            allUser = db.execute("SELECT * FROM user where userid!=?", userId)    
            slim(:start, locals:{user:user,users:allUser, showGrid:true, message:''})
        end 
    end     
end

get('/users/new') do 
    slim(:"users/new",locals:{user:'',users:[], message:'', showGrid:false})
end 

post('/users') do
    userId=params[:userid]
    pwd=params[:pass]
    name=params[:name]
    country=params[:country]
    adress1=params[:adress1]
    adress2=params[:adress2]

    db = connect_to_db("db/hej.db")
    result = db.execute("SELECT MAX(id) as id FROM user;")
    if result.empty? || result[0]['id'] == nil
        # Finns ingen user i databasen, använd id 1
        id = 1
    else
        # Skapa ny user med första lediga id
        
        first_result = result[0]
        id=first_result['id']
        id=id+1  
    end 
    password_digest = BCrypt::Password.create(pwd)
    db.execute("INSERT INTO user('id', 'userid', 'name', 'country', 'pass', 'adress1', 'adress2') VALUES (?,?,?,?,?,?,?);", id,userId,name,country,password_digest,adress1,adress2);
    slim(:index,locals:{user:'',users:[], message:'Användarnamn', showGrid:false})
end 

enable :sessions
get('/users/:id/edit') do 
    # Skickar id som en del av url:en för att testa det också 
    id = params[:id]
    db = connect_to_db("db/hej.db")
    userResult = db.execute("SELECT * FROM user WHERE id=?", id)
    user = userResult[0]
    
    slim(:"users/edit",locals:{user:user,users:[], message:'', showGrid:false})
end

enable :sessions
post('/user/save') do
    # Hämtar id från sessionen 
    id = session[:hejUser]
    pwd=params[:pass]
    userId=params[:userid]
    name=params[:name]
    country=params[:country]
    adress1=params[:adress1]
    adress2=params[:adress2]

    password_digest = BCrypt::Password.create(pwd)

    db = connect_to_db("db/hej.db")
    db.execute("UPDATE user set userid=?, name=?, country=?, pass=?, adress1=?, adress2=? WHERE id=?;", userId,name,country,password_digest,adress1,adress2,id);
    allUsers = db.execute("SELECT * FROM user where userid!=?", userId)   
    userResult = db.execute("SELECT * FROM user WHERE id=?", id)
    user = userResult[0] 
    slim(:start,locals:{user:user,users:allUsers, message:'', showGrid:true})
end 

enable :sessions
get('/chat/:friendId/start') do
     id = session[:hejUser]
    friendId=params[:friendId]
 
     db = connect_to_db("db/hej.db")
     userResult = db.execute("SELECT * FROM user where id=?;", id)
     user = userResult[0]
    friendResult = db.execute("SELECT * FROM user where id=?;", friendId)
    friend = friendResult[0]  

    chatResult = db.execute("SELECT * FROM chat where (user1=? and user2=?) or (user1=? and user2=?);", id,friendId, friendId,id)
    if chatResult.empty? 
        #Ingen chat hittad för användarna
        result = db.execute("SELECT MAX(id) as id FROM chat;")
        if result.empty? || result[0]['id'] == nil
            # Finns ingen chatt i databasen 
            chatId = 1
        else
            # Skapa ny chat med första lediga id
            first_result = result[0]
            chatId = first_result['id'];
            chatId = chatId + 1;
        end 
        db.execute("INSERT INTO chat('id', 'starttime', 'user1', 'user2') VALUES (?, ?, ?, ?);",chatId,Time.now.to_time.to_i,id,friendId);
        chatResult = db.execute("SELECT * FROM chat where user1=? and user2=?;", id,friendId)
        chat = chatResult[0]
    else 
     chat = chatResult[0]
    end
   
    showChatWindow(chat)
end

enable :sessions
post('/chat/:chatId/message') do
    #spara nytt meddelande
    id = session[:hejUser]
    chatId=params[:chatId]
    message=params[:newMessage]

    db = connect_to_db("db/hej.db") 

    result = db.execute("SELECT MAX(id) as id FROM message;")
    if result.empty? || result[0]['id'] == nil
        # Inget message i db Använd id 1
        messageId = 1
    else
        # Skapa nytt message med första lediga id
        first_result = result[0]
        messageId = first_result['id']
        messageId = messageId + 1
   
    end 

    db.execute("INSERT INTO message('id', 'text', 'time', 'chat','user') VALUES (?, ?, ?, ?, ?);", messageId,message,Time.now.to_time.to_i,chatId, id)

    chatResult = db.execute("SELECT * from chat WHERE id=?", chatId)
    chat = chatResult[0]
    showChatWindow(chat)
end 


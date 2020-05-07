require 'sinatra'
require 'slim'
require 'sqlite3'


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
    
    slim(:chat, locals:{user:user,chat:chat,friend:friend,users:allUsers, messages:messageResult, showGrid:true})
  
  end
   
get('/') do
    slim(:index,locals:{user:'',users:[], message:'', showGrid:false})
end

enable :sessions
post('/login') do
    userId=params[:user]
    pwd=params[:pass]
    puts pwd
    puts userId
    db = connect_to_db("db/hej.db")
    userResult = db.execute("SELECT * FROM user where userid=?", userId)
    if userResult
        user = userResult[0]
        if user
            if pwd != user['pass']
                puts user['pass']
                slim(:index,locals:{user:'',users:[], showGrid:false, message:'Fel användare eller passord'})   
            else
                session[:hejUser] = user['id']
                allUser = db.execute("SELECT * FROM user where userid!=?", userId)    
                slim(:start, locals:{user:user,users:allUser, showGrid:true, message:''})
            end 
        else
            slim(:index,locals:{user:'',users:[], message:'Hittar inte användare',showGrid:false})    
        end
    else
        slim(:index,locals:{user:'',users:[], message:'Fel användare eller passord',showGrid:false})    
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

enable :sessions
get('/startChat/:friend') do
  id = session[:hejUser]
  friendId=params[:friend]
 
  db = connect_to_db("db/hej.db")
  userResult = db.execute("SELECT * FROM user where id=?;", id)
  user = userResult[0]
#  allUsers = db.query("SELECT * FROM user;")
  friendResult = db.execute("SELECT * FROM user where id=?;", friendId)
  friend = friendResult[0]  

  chatResult = db.execute("SELECT * FROM chat where (user1=? and user2=?) or (user1=? and user2=?);", id,friendId, friendId,id)
  if chatResult.length() > 0
    chat = chatResult[0]
  else
    result = db.execute("SELECT MAX(id) as id FROM chat;")
    first_result = result[0]
    chatId = first_result['id'];
    chatId = chatId + 1;
    db.execute("INSERT INTO chat('id', 'starttime', 'user1', 'user2') VALUES (?, ?, ?, ?);",chatId,Time.now.to_time.to_i,id,friendId);
    chatResult = db.execute("SELECT * FROM chat where user1=? and user2=?;", id,friendId)
    if chatResult
      chat = chatResult[0]
    end  
  end
  showChatWindow(chat)
# allUsers = db.execute("SELECT * FROM user;")
# messageResult = db.execute("SELECT m.* FROM message m join chat c on m.chat=c.id where c.id=?;", chat["id]"])

#  if friend
#      slim(:chat, locals:{user:user,friend:friend,users:allUsers, messages:messageResult, chat:chat, showGrid:true})
#  end
end

enable :sessions
post('/message/add') do
    id = session[:hejUser]
    chatId=params[:chatId]
    message=params[:newMessage]

    db = connect_to_db("db/hej.db") 

    result = db.execute("SELECT MAX(id) as id FROM message;")
    first_result = result[0]
    messageId = first_result['id']
    if messageId != nil
        messageId = messageId + 1
    else
        messageId = 1
    end 

    db.execute("INSERT INTO message('id', 'text', 'time', 'chat') VALUES (?, ?, ?, ?);", messageId,message,Time.now.to_time.to_i,chatId)

    chatResult = db.execute("SELECT * from chat WHERE id=?", chatId)
    chat = chatResult[0]
    showChatWindow(chat)
end 


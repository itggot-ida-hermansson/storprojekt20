require 'sinatra'
require 'slim'

get('/') do
    slim(:index)
end

post('/login') do
    "Nu är du inloggad"
  end

get('/anders') do
    temp = params[:temp]
    if temp.to_i > 20
        "Väldigt varmt"
    else
      "Brr...kallt"  
    end  
end  

get('/ida') do
      slim(:anders)
end    


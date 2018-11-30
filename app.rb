require 'sinatra'
require 'pg'
require 'uuidtools'

# Listen on all interfaces in the development environment
# This is needed when we run from Cloud 9 environment
# source: https://gist.github.com/jhabdas/5945768
set :bind, '0.0.0.0'
set :port, 8080

get '/' do
  t_msg = []
  t_val_error = []
  
  begin
    # connect to the database
    connection = PG.connect :dbname => 'messageboard', :user => 'messageboarduser', :password => 'messageboarduser'

    # read data from the database
    t_messages = connection.exec 'SELECT * FROM messageboardmessages'

    # map data to t_msg, which is provided to the erb later
    t_messages.each do |s_message|
      t_msg.unshift({ nick: s_message['nickname'], msg: s_message['message'], timestamp: s_message['timestamp'] })
    end

  rescue PG::Error => e
    t_val_error.unshift(e.message.to_s)

  ensure
    connection.close if connection
 
  end

  if params[:validationerror].to_s == "yes"
  
    t_val_error.unshift("Nickname and message should not be empty, and can contain only characters of the english alphabet, numbers and space.")
    
  end
  
  if params[:dberrormsg].to_s != ""
  
    t_val_error.unshift(params[:dberrormsg].to_s)
    
  end

  # call erb, pass parameters to it 
  erb :v_message, :layout => :l_main, :locals => {:t_msg => t_msg, :t_val_error => t_val_error}

end

post '/newmessage' do

  # validate input
  val_input_regex = /^[a-zA-Z0-9 ]*$/
  if ( ( params[:nickname] != "" ) and 
       ( params[:message]  != "" ) and 
       ( params[:nickname] =~ val_input_regex ) and 
       ( params[:message]  =~ val_input_regex ) )

    begin
      # connect to the database
      connection = PG.connect :dbname => 'messageboard', :user => 'messageboarduser', :password => 'messageboarduser'
  
      # generate new UUID
      val_uuid = UUIDTools::UUID.random_create.to_s
  
      # insert data into the database
      timestamp = Time.now
      connection.exec "INSERT INTO messageboardmessages(message_id, nickname, message, timestamp) \
                       VALUES ('#{val_uuid}', '#{params[:nickname]}', '#{params[:message]}', '#{timestamp}');"
  
    rescue PG::Error => e
      val_error = e.message.to_s
      params_for_redirect = {
        :dberror => "yes",
        :dberrormsg => val_error
      }
      query = params_for_redirect.map{|key, value| "#{key}=#{value}"}.join("&")

    ensure
      connection.close if connection
   
    end

    redirect to("/?#{query}")

  else
    # pass the error as a parameter
    params_for_redirect = {
      :validationerror => "yes"
    }
    query = params_for_redirect.map{|key, value| "#{key}=#{value}"}.join("&")
    redirect to("/?#{query}")
  end

end

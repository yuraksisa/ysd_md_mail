# --------------------------------------------------------
# MailDataSystem
# --------------------------------------------------------
#
#  MailBoxes data system implemented in Ruby + DataMapper
#
#  It allows you to implement a mailbox in your site. Create
#  diferent mailboxes and post them the messages sent by the
#  users. Then, each mailbox risponsable, can check it. 
#
#
# --------------------------------------------------------
require 'data_mapper'
require 'dm-constraints'
require 'ysd-md-business_events' if not defined?BusinessEvents

module MailDataSystem

  # ------------------------------------------------------
  # MailBox 
  # ------------------------------------------------------
  # Mails are delivered to mailboxes
  # ------------------------------------------------------
  class MailBox
    include DataMapper::Resource
  
    # DataMapper configuration for the resource  
    storage_names[:default] = 'mailds_mailboxes'
    
    # Properties
    property :address, String, :field => 'address', :length => 20, :key => true
    property :name, String, :field => 'name', :length => 60
    property :description, String, :field => 'description', :length => 256
    property :public_box, Boolean, :default => false # It's a public mailbox, everybody can read it
    property :type, String, :field => 'type', :length => 10, :default => 'mail'
       
    #
    # Find mailboxes of a concrete type
    #
    def self.find_mailboxes_by_type(type, options={}) 
    
      merged_options = options.merge(:type => type)    
      MailBox.all(merged_options)
    
    end
    
    #
    # Count mailboxes of a concrete type
    #
    def self.count_mailboxes_by_type(type)
    
       begin # Count does not work for all adapters
         total=MailBox.count
       rescue
         total=MailBox.all.length
       end     
    
    end
    
    #
    # Find messages from a mailbox (last message of each conversation)
    #
    def self.find_messages(mailbox_address, from=0, quantity=20, folder = :in)
         
      messages=repository(:default).adapter.select("SELECT MAX(ID) AS MAX_ID FROM MAILDS_MAILS WHERE CONVERSATION_ID IN ( SELECT CONVERSATION_ID FROM MAILDS_MAILS WHERE MAILBOX_ID = '#{mailbox_address}' AND MAILDS_MAILS.FOLDER = '#{folder}' ) GROUP BY CONVERSATION_ID ORDER BY MAX(ID) DESC LIMIT #{quantity} OFFSET #{from}")
   
      MailDataSystem::Mail.all(:id => messages, :order => [:received_date.desc])
    
    end
    
    #
    # Count the total conversations in a mailbox folder
    #
    def self.count_conversations(mailbox_address, folder)
      
      count = repository(:default).adapter.select("SELECT COUNT(*) FROM MAILDS_CONVERSATIONS WHERE ID IN (SELECT CONVERSATION_ID FROM MAILDS_MAILS WHERE MAILDS_MAILS.MAILBOX_ID = '#{mailbox_address}' AND MAILDS_MAILS.FOLDER = '#{folder}' )")
          
      count

    end
    
  end

  # -----------------------------------------------------
  # Conversations
  # -----------------------------------------------------
  # Represents a conversations : A set of related messages
  # that have been changed between two senders
  # -----------------------------------------------------
  class Conversation
    include DataMapper::Resource
     
    # DataMapper configuration for the resource
    storage_names[:default] = 'mailds_conversations'
    
    # Properties
    property :id, Serial, :field => 'id', :key => true
    property :topic, String, :field => 'topic', :length=>80
    
    has n, :mails, 'Mail', :child_key => [:conversation_id], :parent_key => [:id], :constraint => :destroy
            
    #
    # Find the last conversation message
    #       
    def self.find_last_message(conversation_id)
    
      messages=repository(:default).adapter.select("SELECT MAX(ID) AS MAX_ID FROM MAILDS_MAILS WHERE CONVERSATION_ID = '#{conversation_id}' GROUP BY CONVERSATION_ID")  
      result = MailDataSystem::Mail.all(:id => messages)
 
    end        
            
  end

  # -----------------------------------------------------
  # Mail 
  # -----------------------------------------------------
  # Represents a message
  # -----------------------------------------------------
  class Mail
    include DataMapper::Resource
        
    # DataMapper configuration for the resource
    storage_names[:default] = 'mailds_mails'
    
    # Properties
    property :id, Serial, :field => 'id', :key => true 
    belongs_to :mailbox, 'MailBox', :child_key => [:mailbox_id] # A mail is hosted in a mailbox
    property :folder, String, :field => 'folder', :length => 30, :default => 'out'
    property :subject, String, :field => 'subject', :length => 50
    property :message, String, :field => 'message', :length => 1024
    belongs_to :sender, 'MailBox', :child_key => [:sender_id], :required => false # A mail is sent by a sender
    belongs_to :receiver, 'MailBox', :child_key => [:receiver_id], :required => false # A mail is sent to a receiver
    belongs_to :reply, 'Mail', :child_key => [:reply_id], :required => false # This mail is a reponse of the reply message
    belongs_to :reply_by, 'Mail', :child_key => [:reply_by_id], :required => false # This mail is responded by the reply_by message
    property :sender_name, String, :field => 'sender_name', :length => 60
    property :sender_company, String, :field => 'sender_company', :length => 50
    property :sender_phone, String, :field => 'sender_phone', :length => 15
    property :sender_email, String, :field => 'sender_email', :length => 40
    property :received_date, DateTime, :field => 'received_date'
    property :read, Boolean, :default => false
    belongs_to :conversation, 'Conversation', :child_key => [:conversation_id], :parent_key => [:id], :required => false # A mail belongs to a conversation
    property :conversation_number, Integer, :field => 'conversation_number', :default => 0
    property :reference_origin, String, :field => 'reference_origin', :length => 80
    property :reference_destination, String, :field => 'reference_destination', :length => 80
  
    # post is an alias for the save method
    alias old_save save
    
    # 
    # Before create (data initialization)
    #
    before :create do |mail| 
      mail.mailbox = mail.sender if (not mail.mailbox and mail.sender) 
      mail.received_date = Time.now if mail.received_date.nil?
    end
  
    #
    # After create (holds that the message is responded)
    #
    after :create do |mail|
    
      if mail.reply and mail.reply.id
        responded_by = Mail.get(mail.reply.id)
        responded_by.update({:reply_by => self}) if responded_by
      end
      
      # Notifies that a new message has been received
      if defined?BusinessEvents and mail.folder == 'in' 
        BusinessEvents::BusinessEvent.fire_event(:mail_received, {:mailbox => mail.mailbox.address} )
      end

     
    end
  
    #
    # Redefines the save method to find or create the mailbox first
    #
    def save
                             
      # sender
      if self.sender and not(self.sender.saved?)
        self.sender = MailBox.first_or_create(:address=>self.sender.address)  #, :name=>self.sender.name)
      end 

      # receiver
      if self.receiver and not(self.receiver.saved?)
        self.receiver = MailBox.first_or_create(:address=> self.receiver.address) #, :name=>self.receiver.name)
      end  
   
      # mailbox
      if self.mailbox and not(self.mailbox.saved?)
        self.mailbox = MailBox.first_or_create(:address => self.mailbox.address) #, :name => self.mailbox.name) 
      end
      if (self.mailbox.nil? and self.sender)        
        self.mailbox = MailBox.first_or_create(:address => self.sender.address) #, :name => self.sender.name) 
      end
                                  
      # reply and conversation 
      if self.reply # It is a message response
        self.reply = Mail.get(self.reply.id) if not(self.reply.saved?)
        self.conversation = Conversation.get(self.reply.conversation.id) 
        self.conversation_number = (Mail.count('conversation.id' => self.conversation.id) + 1) if self.new?
        self.reference_destination = self.reply.reference_origin if self.reply.reference_origin 
      else          # It is a new message (new conversation)
        if self.conversation 
          self.conversation = Conversation.first_or_create(:id => self.conversation.id) unless self.conversation.saved?            
        else
          self.conversation = Conversation.create(:topic => self.subject)     
        end
      end
         
      puts "Vamos a guardar : #{self.to_json}"   
            
      # Saves the message
      old_save
  
      send_mail if self.folder == 'out' # send the message
            
    end
  
    private
   
    # 
    # Send the message
    # 
    #private @api
    def send_mail
    
      puts "send_mail"
      if self.folder == 'out' # If the message is in the "out" folder 
 
        # Create the message in the [in] folder of the receiver                
        message = self.attributes.merge( :id => nil, :mailbox => MailBox.new(:address => self.receiver.address), :sender => MailBox.new(:address => self.sender.address), :receiver => MailBox.new(:address => self.receiver.address), :folder => 'in', :reply => (self.reference_destination.to_i > 0)?Mail.new(:id => self.reference_destination.to_i):nil , :conversation => (self.reply and self.reply.conversation.id)?Conversation.new(:id=>self.reply.conversation.id):Conversation.new(:topic => self.subject) , :reference_origin => self.id )
                
        inbox_message = Mail.create(message) if self.sender and self.receiver
        
        # Move the message to the sent folder
        self.update( :folder => 'sent' ) # When a message is sent the folder is updated to sent
      
      end
    
    end
     
    # Alias for methods and properties
    alias post save 
    alias from sender
    alias to receiver
  end

  

end
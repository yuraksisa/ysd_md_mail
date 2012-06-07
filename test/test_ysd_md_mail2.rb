require 'ysd_core_incompatibilities'
#Conectar a la base de datos
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, {:adapter => 'postgres',:database => 'me_entiendes',:host => '192.168.1.133',:username => 'development',:password => 'developer'})
DataMapper.finalize
DataMapper.auto_migrate!
DataMapper.auto_upgrade!

# Crear el mensaje

mail_1 = MailDataSystem::Mail.new(:sender=>MailDataSystem::MailBox.new(:address=>'a', :name=>'Juan'), :receiver=>MailDataSystem::MailBox.new(:address => 'b', :name=>'Pedro'), :subject => 'hola', :message => 'hola, holita')
mail_1.post  

mail_2 = MailDataSystem::Mail.new(:sender=>MailDataSystem::MailBox.new(:address => 'b', :name=>'Pedro'), :receiver=>MailDataSystem::MailBox.new(:address=>'a', :name=>'Juan'), :subject => 'hola', :message => 'adios', :reply => MailDataSystem::Mail.new(:id=>2))
mail_2.post

mail_3 = MailDataSystem::Mail.new(:sender=>MailDataSystem::MailBox.new(:address=>'a', :name=>'Juan'), :receiver=>MailDataSystem::MailBox.new(:address => 'b', :name=>'Pedro'), :subject => 'hola', :message => 'ei!', :reply => MailDataSystem::Mail.new(:id=>4))

mail_4 = MailDataSystem::Mail.new(:sender=>MailDataSystem::MailBox.new(:address => 'b', :name=>'Pedro'), :receiver=>MailDataSystem::MailBox.new(:address=>'a', :name=>'Juan'), :subject => 'hola', :message => 'amigo!', :reply => MailDataSystem::Mail.new(:id=>6))



MailDataSystem::Conversation.all(:mails => {'mailbox.address' => 'delphiero'})


MailDataSystem::Conversation.all(:mails => {'mailbox.address' => 'delphiero'}).mails.last
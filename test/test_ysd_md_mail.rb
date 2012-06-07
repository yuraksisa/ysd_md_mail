require '../lib/ysd_md_mail'

DataMapper::Logger.new($stdout, :debug)

# Configure the conection to the repository
DataMapper.setup(:default, { 
	:adapter => 'postgres',
	:database => 'yurak_sisa',
	:host => '192.168.1.133',
	:username => 'development',
	:password => 'developer'
})

# Prepare the DataMapper
DataMapper.finalize

# Create a message to the contact form mailbox
#MailSystem::MailBox.get("contact form").post MailSystem::Mail.new ("delphiero50@gmail.com", "We wish ...") 
MailSystem::Mail.new(:subject=>'Language request')
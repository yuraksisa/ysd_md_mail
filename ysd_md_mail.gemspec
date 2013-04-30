Gem::Specification.new do |s|
  s.name    = "ysd_md_mail"
  s.version = "0.2.0"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2011-08-23"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb']
  s.summary = "A DattaMapper-based model for mailing system"
  s.homepage = "http://github.com/yuraksisa/ysd_md_mail"
    
  s.add_runtime_dependency "data_mapper", "1.2.0"
  
  s.add_runtime_dependency "ysd_md_business_events"
  s.add_runtime_dependency "ysd_md_profile"

end
Gem::Specification.new do |s|
  s.name = "work-order-worker"
  s.version = "0.0.1"
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary = "Base Work Order Processing Functionality"
  s.homepage = "http://github.com//work-order-worker"
  s.email = "mfoster@mdsol.com"
  s.authors = ["Eric Anderson", "Mark W. Foster"]
  s.has_rdoc = false

  s.files = %w( README.md )
  s.files += Dir.glob("lib/**/*")
  s.add_dependency('json')
  s.add_dependency('rest-client')
end

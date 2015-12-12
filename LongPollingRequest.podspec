Pod::Spec.new do |s|
  s.module_name = 'LongPollingRequest'
  s.name = 'LongPollingRequest'
  s.version = '0.0.1'
  s.license = 'MIT'
  s.summary = 'Long Polling Request for @levantAJ team'
  s.homepage = 'https://github.com/levantAJ'
  s.authors = { 'Le Tai' => 'sirlevantai@gmail.com' }
  s.source = {  :git => 'https://github.com/levantAJ/LongPollingRequest.git', :tag => s.version}
  s.source_files = 'LongPollingRequest/**/*.{h,swift}'
  s.resources = "LongPollingRequest/**/*.{xib}"
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
end

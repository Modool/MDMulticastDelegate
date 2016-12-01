Pod::Spec.new do |s|
    s.name = 'MDMulticastDelegate'
    s.version = '1.0.0'
    s.summary = 'A short description of MDMulticastDelegate.'
    s.description = <<-DESC
    A longer description of MDMulticastDelegate in Markdown format.
    * Think: Why did you write this? What is the focus? What does it do?
    * CocoaPods will be using this to generate tags, and improve search results.
    * Try to keep it short, snappy and to the point.
    * Finally, don't worry about the indent, CocoaPods strips it!
    DESC
    s.homepage = 'https://github.com/MarkeJave/MDMulticastDelegate'
    s.license = 'MIT'
    s.author = { 'MarkeJave' => '308865427@qq.com' }
    s.source = { :git => 'https://github.com/MarkeJave/MDMulticastDelegate.git', :tag => s.version.to_s }
    s.source_files = 'MDMulticastDelegate.{h,m}'
    s.requires_arc = true
    s.frameworks = 'Foundation'
    s.platform = :ios
    s.ios.deployment_target = '7.0'
end

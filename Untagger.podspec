#
# Be sure to run `pod lib lint Untagger.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Untagger'
  s.version          = '0.0.3'
  s.summary          = 'Removal and full text extraction of HTML in Swift inspired by Boilerpipe'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Untagger is a removal and full text extraction of HTML written in Swift heavily inspired by Boilerpipe. It allows you to get the title and the text body of an HTML page.
                       DESC

  s.homepage         = 'https://github.com/wcgray/Untagger'
  #s.screenshots     = 'https://github.com/wcgray/Untagger/blob/master/demo.gif'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wcgray' => 'cam@tinsoldiersoftware.com' }
  s.source           = { :git => 'https://github.com/wcgray/Untagger.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.swift_version = '4.0'
  s.source_files = 'Untagger/**/*.{swift,m,h}'
  s.public_header_files = 'Untagger/**/*.h'
  s.module_name = 'Untagger'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.library = 'xml2'
  s.frameworks = 'Foundation'
end

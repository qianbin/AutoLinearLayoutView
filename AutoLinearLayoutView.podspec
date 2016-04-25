#
# Be sure to run `pod lib lint AutoLinearLayoutView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "AutoLinearLayoutView"
  s.version          = "0.2.0"
  s.summary          = "Auto-Layout based LinearLayout View."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
LinearLayout Linear UIStackView StackView
                       DESC

  s.homepage         = "https://github.com/qianbin/AutoLinearLayoutView"
  s.screenshots     = "https://raw.githubusercontent.com/qianbin/AutoLinearLayoutView/master/screenshot4.gif"
  s.license          = 'MIT'
  s.author           = { "QianBin" => "cola.tin.com@gmail.com" }
  s.source           = { :git => "https://github.com/qianbin/AutoLinearLayoutView.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'AutoLinearLayoutView' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

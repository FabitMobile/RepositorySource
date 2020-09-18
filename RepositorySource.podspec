#
# Be sure to run `pod lib lint RepositorySource.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RepositorySource'
  s.version          = '3.1.1'
  s.summary          = 'CoreData/UrlSession wrapper'
  s.homepage         = 'https://github.com/FabitMobile/RepositorySource.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'fabit_mobile' => 'aleksandr.zherebtsov@gorparkovki.ru' }
  s.source           = { :git => 'https://github.com/FabitMobile/RepositorySource.git', :tag => s.version.to_s }
  s.swift_version     = '5.2'
  s.ios.deployment_target = '9.0'

  s.source_files = 'RepositorySource/Source/**/*'
  
  s.dependency 'FastEasyMapping', '~> 1.0'
  s.dependency 'PromiseKit', '~> 6.0'
  s.dependency 'FoundationExtension', '~> 1.0.3'
  s.dependency 'ReachabilitySwift', "~> 5.0" 


end

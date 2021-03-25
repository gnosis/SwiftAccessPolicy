Pod::Spec.new do |spec|
    spec.name         = "SwiftAccessPolicy"
    spec.version      = "1.0.0"
    spec.summary      = "Simple Password & Biometry authorisation with sessions"
    spec.description  = <<-DESC
    This library implements usage of biometry, password-based acces, and different access policies useful for implementing
    authentication in iOS apps.
                     DESC
    spec.homepage     = "https://github.com/gnosis/SwiftAccessPolicy"
    spec.license      = { :type => "MIT", :file => "LICENSE" }
    spec.author             = { "Dmitry Bespalov" => "dmitry.bespalov@gnosis.io", "Andrey Scherbovich" => "andrey@gnosis.io" }
    spec.cocoapods_version = '>= 1.4.0'
    spec.platform     = :ios, "13.0"
    spec.swift_version = "5.0"
    spec.source       = { :git => "https://github.com/gnosis/SwiftAccessPolicy.git", :tag => "#{spec.version}" }
    spec.source_files  = "Sources/**/*.swift"
    spec.requires_arc = true
  end


Pod::Spec.new do |s|
  s.name         = "AeroGear-Diff-Patch"
  s.version      = "0.1.0"
  s.summary      = "AeroGear Diff Patch."
  s.homepage     = "https://github.com/corinnekrych/aerogear-diff-patch-ios"
  s.license      = 'Apache License, Version 2.0'
  s.author       = "Red Hat, Inc."
  s.source       = { :git => 'https://github.com/corinnekrych/aerogear-diff-patch-ios.git' }
  s.platform     = :ios, 5.0
  s.source_files = 'diff-patch/**/*.{h,m}'
  s.public_header_files = 'diff-patch/AeroGearDiffPatch.h'
  s.requires_arc = true
end

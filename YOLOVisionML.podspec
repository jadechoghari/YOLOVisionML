Pod::Spec.new do |spec|

  spec.name         = "YOLOVisionML"
  spec.version      = "0.0.1"
  spec.summary      = "YOLOVisionML simplifies CoreML YOLO model output processing for machine learning integration. "

  spec.swift_versions    = '5.0'
  spec.description  = <<-DESC
    YOLOVisionML simplifies YOLO model output processing. Achieve accurate bounding boxes and mask calculations, advancing object detection and machine learning capabilities. This library performs conversion for any YOLO Model that has been converted to CoreML, as well as outputs that are tensors and conforms to Ultralytics form
                   DESC

  spec.homepage     = "https://github.com/jadechoghari/YOLOVisionML.git"


  spec.license      = { :type => "MIT", :file => "LICENSE" }


  spec.author             = { "Jade Choghari" => "chogharijade@gmail.com" }
  spec.social_media_url   = "https://twitter.com/jadechoghari"
  
  
  spec.ios.deployment_target = "11.0"
  
  spec.readme = "https://raw.githubusercontent.com/jadechoghari/YOLOVisionML/main/README.md"
  
  spec.source       = { :git => "https://github.com/jadechoghari/YOLOVisionML.git", :tag => "#{spec.version}" }
  spec.source_files  = "YOLOVisionML/**/*.{swift,h,m}"


end

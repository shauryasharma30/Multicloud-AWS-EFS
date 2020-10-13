provider "aws" {
  region     = "ap-south-1"
  profile    = "task2"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "mybucket787"
  acl    = "private"

  tags = {
    Name = "Mybucket-task2"
  }
}


resource "aws_s3_bucket_object" "image" {
depends_on = [
aws_s3_bucket.bucket,
]
bucket = "mybucket787"
	key = "t2.png"
        source = "C:/Users/shaurya/Desktop/TASK2/photo/t2.png"
	etag = filemd5("C:/Users/shaurya/Desktop/TASK2/photo/t2.png")
	
	acl = "public-read"

}

resource "aws_s3_bucket_public_access_block" "type" {
  bucket = "${aws_s3_bucket.bucket.id}"
  block_public_acls   = false
  block_public_policy = false
}

locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_distribution" "webcloud" {
  origin {
    domain_name = "${aws_s3_bucket.bucket.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"
custom_origin_config {
    http_port = 80
    https_port = 80
    origin_protocol_policy = "match-viewer"
    origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
    }
  }
enabled = true
default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"
forwarded_values {
    query_string = false
cookies {
      forward = "none"
      }
    }
viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
viewer_certificate {
    cloudfront_default_certificate = true
  }
}
resource "null_resource" "webip"  {
 provisioner "local-exec" {
     command = "echo  ${aws_cloudfront_distribution.webcloud.domain_name} > Cloudfront.txt"
   }
}

#Создать контейнер для бесплатного контента.
resource "aws_s3_bucket" "free_bucket" {
  bucket = "free-bucket-084525207573-csa-account-009" 
}

resource "aws_s3_bucket_ownership_controls" "free_bucket_ownership_controls" {
  bucket = aws_s3_bucket.free_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#resource "aws_s3_bucket_public_access_block" "free_bucket_public_access_block" {
#  bucket = aws_s3_bucket.free_bucket.id

#  block_public_acls       = false
#  block_public_policy     = false
#  ignore_public_acls      = false
#  restrict_public_buckets = false
#}

resource "aws_s3_bucket_acl" "free_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.free_bucket_ownership_controls,
 #   aws_s3_bucket_public_access_block.free_bucket_public_access_block,
  ]

  bucket = aws_s3_bucket.free_bucket.id
 # acl    = "public-read"
  acl    = "private"
}

#Создать контейнер для платного контента.
resource "aws_s3_bucket" "paid_bucket" {
  bucket = "paid-bucket-084525207573-csa-account-009" 
}

resource "aws_s3_bucket_ownership_controls" "paid_bucket_ownership_controls" {
  bucket = aws_s3_bucket.paid_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "paid_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.paid_bucket_ownership_controls,
  ]

  bucket = aws_s3_bucket.paid_bucket.id
  acl    = "private"
}

# Создать группу для пользователей бесплатного контента. (Для AWS на вебинаре было сказано не использовать группы)
resource "aws_iam_user" "free_user" {
    name = "free_user"
    path          = "/"
    force_destroy = true	
}

resource "aws_iam_user_login_profile" "free_user_profile" {
  user    = aws_iam_user.free_user.name
  pgp_key = file("public.gpg")
}

output "free_user_password" {
  value = aws_iam_user_login_profile.free_user_profile.encrypted_password
}

# Создать группу для пользователей платного контента. (Для AWS на вебинаре было сказано не использовать группы)
resource "aws_iam_user" "paid_user" {
    name = "paid_user"
    path          = "/"
    force_destroy = true	
}

resource "aws_iam_user_login_profile" "paid_user_profile" {
  user    = aws_iam_user.paid_user.name
  pgp_key = file("public.gpg")
}

output "paid_user_password" {
  value = aws_iam_user_login_profile.paid_user_profile.encrypted_password
}

# Предоставить право на чтение контейнера "Бесплатный контент" для групп "Бесплатный контент" и "Платный контент"
resource "aws_s3_bucket_policy" "free_policy" {
  bucket = aws_s3_bucket.free_bucket.id
  policy = data.aws_iam_policy_document.free_policy_document.json
}

data "aws_iam_policy_document" "free_policy_document" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.free_user.arn, aws_iam_user.paid_user.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
	
	effect = "Allow"	

    resources = [
      aws_s3_bucket.free_bucket.arn,
      "${aws_s3_bucket.free_bucket.arn}/*",
    ]
  }
}

# Предоставть право на чтение контейнера "Платный контент" для группы "Платный контент"
resource "aws_s3_bucket_policy" "paid_policy" {
  bucket = aws_s3_bucket.paid_bucket.id
  policy = data.aws_iam_policy_document.paid_policy_document.json
}

data "aws_iam_policy_document" "paid_policy_document" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.paid_user.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

	effect = "Allow"

    resources = [
      aws_s3_bucket.paid_bucket.arn,
      "${aws_s3_bucket.paid_bucket.arn}/*",
    ]
  }
}

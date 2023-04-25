provider "aws" {
  region = "us-west-2"
}

# Configure the AWS Provider
# provider "aws" {
#   region     = "us-east-1"
#   access_key = "AKIAUARQXPL5RYALRIOS"
#   secret_key = "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"
#   allowed_account_ids = 276053850875
#}
provider "random" {
}

# get EKS authentication for being able to manage k8s objects from terraform
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
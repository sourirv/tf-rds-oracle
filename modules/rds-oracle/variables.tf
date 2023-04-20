
variable "environment" {
  description = "The deployment environment dev|cicd|test|prod etc."
  type        = string
}

variable "bucket_name" {
  description = "The name of the s3 bucket where state is stored"
  type        = string
}

variable "_depends_on" {
  description = "The list of dependencies for the module"
  type        = any
  default     = []
}

variable "state_key" {
  description = "The key in the s3 bucket where state is stored"
  type        = string
  default = "tfstate"
}

variable "region" {
  description = "The region for primary RDS"
  type        = string
  default = "us-east-2"
}

variable "region2" {
  description = "The backup region for rds"
  type        = string
  default = "us-east-1"
}

variable "identifier" {
  description = "The identifier of the RDS instance"
  type        = string
  default = "rds-oracle-test"
}

variable "debug_mode" {
  description = "Indicates whether to run deployment in debug mode"
  type        = bool
  default     = true
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
    http = {
      source = "hashicorp/http"
    }
    archive = {
      source = "hashicorp/archive"
    }
    checkmate = {
      source  = "tetratelabs/checkmate"
      version = "1.6.0"
    }
  }
}
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = ">= 2.0.0"
    }
  }

  backend "http" {
    # Expected Gitea HTTP backend path: http://<gitea-url>/api/packages/<owner>/terraform/state/prod-lon-fabric-policies
  }
}

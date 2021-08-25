project = "psc-ws-maj"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "psc" }

runner {
    enabled = true
    data_source "git" {
        url = "https://github.com/prosanteconnect/psc-ws-maj.git"
    }
}

# An application to deploy.
app "prosanteconnect/psc-ws-maj" {
    # Build specifies how an application should be deployed. In this case,
    # we'll build using a Dockerfile and keeping it in a local registry.
    build {
        use "docker" {}
        # Uncomment below to use a remote docker registry to push your built images.
        registry {
            use "docker" {
                image = "prosanteconnect/psc-ws-maj"
                tag   = gitrefpretty()
                encoded_auth = filebase64("/secrets/dockerAuth.json")
            }
        }
    }

    # Deploy to Nomad
    deploy {
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/psc-ws-maj.nomad.tpl", {
                public_hostname = var.public_hostname
            })
        }
    }
}

variable "public_hostname" {
type    = string
default = "psc-ws-maj.psc.api.esante.gouv.fr"
}

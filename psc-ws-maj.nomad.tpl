job "psc-ws-maj" {
    datacenters = ["dc1"]
    type = "service"

    vault {
        policies = ["psc-ecosystem"]
        change_mode = "restart"
    }
    group "psc-ws-maj" {
        count = "1"
        restart {
            attempts = 3
            delay = "60s"
            interval = "1h"
            mode = "fail"
        }
        update {
            max_parallel      = 1
            canary            = 1
            min_healthy_time  = "30s"
            progress_deadline = "5m"
            healthy_deadline  = "2m"
            auto_revert       = true
            auto_promote      = true
        }
        network {
            mode = "host"
            port "http" {
                to = 80
            }
        }
        task "psc-ws-maj" {
            driver = "docker"
            config {
                image = "${artifact.image}:${artifact.tag}"
                ports = ["http"]
                mounts = [
                    {
                        type    = "bind"
                        target  = "/var/www/html/.env"
                        source  = "secrets/.env"
                    }
                ]
                extra_hosts = ["in.api.test.henix.asipsante.fr:151.80.119.235"]
            }
            template {
                data = <<EOH
{{ with secret "psc-ecosystem/psc-ws-maj" }}{{ .Data.data.psc_public_key }}{{ end }}
EOH
                destination = "secrets/public_key.pem"
            }
            template {
                data = <<EOH
                    APP_NAME=psc-ws-maj
                    APP_ENV=test
                    APP_KEY={{ with secret "psc-ecosystem/psc-ws-maj" }}{{ .Data.data.app_key }}{{ end }}
                    APP_DEBUG=true
                    APP_URL=https://localhost

                    API_URL="http://{{ range service "psc-api-maj" }}{{ .Address }}:{{ .Port }}{{ end }}/api"
                    IN_RASS_URL="https://in.api.test.henix.asipsante.fr/api/lura/ing/rass/users"

                    PROXY_URL="https://psc-ws-maj.psc.api.esante.gouv.fr"
                    PROXY_SCHEMA=https

                    LOG_CHANNEL=errorlog
                    LOG_LEVEL=info

                    RABBITMQ_HOST={{ range service "psc-rabbitmq" }}{{ .Address }}{{ end }}
                    RABBITMQ_PORT={{ range service "psc-rabbitmq" }}{{ .Port }}{{ end }}
                    RABBITMQ_USER="{{ with secret "psc-ecosystem/rabbitmq" }}{{ .Data.data.user }}{{ end }}"
                    RABBITMQ_PASSWORD="{{ with secret "psc-ecosystem/rabbitmq" }}{{ .Data.data.password }}{{ end }}"

                    SESSION_DRIVER=cookie
                    SESSION_LIFETIME=10

                    PROSANTECONNECT_CLIENT_ID={{ with secret "psc-ecosystem/psc-ws-maj" }}{{ .Data.data.psc_client_id }}{{ end }}
                    PROSANTECONNECT_CLIENT_SECRET={{ with secret "psc-ecosystem/psc-ws-maj" }}{{ .Data.data.psc_client_secret }}{{ end }}
                    PROSANTECONNECT_REDIRECT_URI="https://psc-ws-maj.psc.api.esante.gouv.fr/ui/auth/prosanteconnect/callback"
                    PUBLIC_KEY_FILE=/secrets/public_key.pem
                EOH
                destination = "secrets/.env"
                change_mode = "restart"
            }
            resources {
                cpu = 1024
                memory = 2048
            }
            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
                tags = ["urlprefix-${public_hostname}/"]
                canary_tags = ["canary instance to promote"]
                port = "http"
                check {
                    type = "http"
                    port = "http"
                    path = "/ui"
                    interval = "10s"
                    timeout = "2s"
                }
            }
        }
    }
}

# Shared Services Repository
## Purpose
This repository is responsible for provisioning Traefik and Visualizer as Shared Docker services. Traefik is responsible for dynamically retrieving certificates for registered application domains and for routing to the appropriate container based upon their hostname within these domains. Visualizer is just a simple dashboard that allows the current state of the Swarm to be viewed through a web page.

## Branching Model
### Overview
This repository contains definitions that need to follow an organization's environment model with changes deployed to non-production environments and tested before being deployed to the production environment.  To account for this I am using a branch-based deployment model wherein a permanent branch is created to represent each of the runtime environments supported by an organization. Terraform workspaces are created to mirror this approach so that state will be maintained at a branch/environment level.  The workspace is then used within the Terraform templates to assign environment-specific names to security groups, instances, DNS entries, etc.

### Detail
1. Modifications are made to feature branches created from the development branch.
2. Feature branches are then merged into the development branch via pull-request.
3. The development branch will automatically create/update Docker instances running in the development environment.
4. Once the change has been tested in the development environment they can be merged into the production branch.
5. The production branch will automatically create/update Docker instances running in the production environment when updated.

## Pipeline
1. All Terraform files will be validated whenever any branch is updated.
2. A Terraform Plan is run and the plan persisted whenever the development or production branches change.
3. A Terraform Apply is run for the persisted plan whenever the development or production branches change.

## Terraform
## Inputs
| Variable | Description |
| -------- | ----------- |
| DOCKER_CA_CERT |  |
| DOCKER_CLIENT_CERT |  |
| DOCKER_CLIENT_KEY |  |
| SSH_PRIVATE_KEY | The user that we should use for ssh connections. This is used to connect to a Docker node to provision a directory under the EFS mount for Traefik to store its data. |
| AWS_ACCESS_KEY_ID | This is the AWS access key used by Traefik to create text records in Route 53 while negotiating with Lets Encrypt to obtain new TLS certificates. |
| AWS_SECRET_ACCESS_KEY | This is the AWS secret key used by Traefik to create text records in Route 53 while negotiating with Lets Encrypt to obtain new TLS certificates. |

## Processing
1. Uses data sources to obtain the Route 53 zone to create DNS entries in and the public IPs of the running Docker instances to associate them with.
2. Creates health checks for all of the registered Docker instances.
3. Creates a load-balanced and fail-over capable DNS record in Route 53 for Traefik.
4. Creates a load-balanced and fail-over capable DNS record in Route 53 for Visualizer.
5. Provisions both the Traefik and Visualizer services.

## Outputs
None

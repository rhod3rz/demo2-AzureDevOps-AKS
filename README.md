## An Azure DevOps and Azure Kubernetes Service demo pipeline.

### Summary
This repo demonstrates a web app deployment to Azure Kubernetes Service. The project is broken down into three pipelines:

- An infrastructure build pipeline (using Terraform)
- An application code build pipeline
- An application code release pipeline

The core application components are:

- A voting application
- An analytics api
- An Azure Database for MySQL

In addition it demonstrates the use of several other technologies and concepts:

- Git and git branching strategy ( prd | dev | stg )
- Azure Application Gateway fronting both apps and protected with a TLS certificate
- Hub and spoke network design with Azure Firewall for outbound traffic
- Docker application build with an Azure Container Registry repo
- Terraform provision of prd, dev or stg Azure Kubernetes Service (AKS) environments based on branch name
- Authorisation gate to control and review terraform code changes
- Kubernetes application deployment including the following features:
  - AGIC: Application gateway add-on
  - CSI Driver: Azure keyvault secret retrieval
  - AKV2K8S: Azure key vault TLS certificate synchronisation
  - OMS: Azure monitor integration
  - Cluster and pod (HPA) autoscalers
  - Azure CNI networking
  - Azure AD integration and role based access control
- Emergency rollback using kubectl & previous versions

### Pipeline Overview
![Pipeline Overview](https://raw.githubusercontent.com/rhod3rz/demo2-AzureDevOps-AKS/prd/screenshots/pipeline-overview.png "Pipeline Overview")

### Infrastructure Diagram
![Infrastructure Diagram](https://raw.githubusercontent.com/rhod3rz/demo2-AzureDevOps-AKS/prd/screenshots/infrastructure.png "Infrastructure Diagram")

### K8s Diagram
![K8s Diagram](https://raw.githubusercontent.com/rhod3rz/demo2-AzureDevOps-AKS/prd/screenshots/k8s.png "K8s Diagram")

### Pre-Requisites
The pipeline relies on the following components:

- Azure DevOps Service Connection  
An ADO service connection to Azure called 'payg2106'.  

- Azure DevOps Service Connection - Azure Container Registry (aka Docker Registry)  
An ADO service connection to Docker / Azure Container Registry called 'acrdlnteudemoapps210713'.

- Azure DevOps Variable Group (Linked to KeyVault)  
An ADO variable group linked to azure key vault called 'kv-core-210713', and containing ARM-ACCESS-KEY, ARM-CLIENT-SECRET, KV-ARM-CLIENT-ID and KV-ARM-TENANT-ID.

&nbsp;
### 1. The 'Infrastructure' Pipeline Workflow

The infrastructure pipeline focusses on building the Azure components. As changes are infrequently made to the infrastructure the pipeline 'trigger' is a manual process.

---
#### 1.1 Setup ADO Project.
---
a. In ADO create a project, then pipelines > new pipeline > github/yaml > select the correct repo > then create pipelines for the following files and rename as below:  

| YAML File | Rename Pipeline To |
| ------ | ----------- |
| 1-voteapp-infrastructure.yml | 1-voteapp-infrastructure |
| 2-voteapp-build.yml | 2-voteapp-build |
| 3-voteapp-release.yml | 3-voteapp-release |

#### 1.2 Build the 'prd' Branch.
---
a. Manually run the '1-voteapp-infrastructure' pipeline. Review the plan at the 'Wait for Validation' stage, and if happy authorise to proceed.  

Pipeline Actions:
- Evaluates the branch name and Terraform provisions the 'prd' environment (inc. manual approval gate).

Output:
- You now have one environment deployed, 'prd'.

---
#### 1.2 Build the 'dev' Branch.
---
a. Create a new branch 'dev', and switch to it.  
`git checkout -b dev`  
b. Push the 'dev' branch to github.  
`git add .`  
`git commit -m "dev infrastructure deployment"`  
`git push -u origin dev`  
c. Manually run the pipeline. Review the plan at the 'Wait for Validation' stage, and if happy authorise to proceed.  
d. Once built you can delete the 'dev' branch.  
`git checkout prd`  
`git push -d origin dev`  
`git branch -d dev`  
`git remote prune origin`  
`git pull origin prd`  

Pipeline Actions:
- Evaluates the branch name and Terraform provisions the 'dev' environment (inc. manual approval gate).

Output:
- You now have two environments deployed, 'prd' and 'dev'.

---
#### 1.3 Build the 'stg' Branch.
---
a. Create a new branch 'stg', and switch to it.  
`git checkout -b stg`  
b. Push the 'stg' branch to github.  
`git add .`  
`git commit -m "stg infrastructure deployment"`  
`git push -u origin stg`  
c. Manually run the pipeline. Review the plan at the 'Wait for Validation' stage, and if happy authorise to proceed.  
d. Once built you can delete the 'stg' branch.  
`git checkout prd`  
`git push -d origin stg`  
`git branch -d stg`  
`git remote prune origin`  
`git pull origin prd`  

Pipeline Actions:
- Evaluates the branch name and Terraform provisions the 'stg' environment (inc. manual approval gate).

Output:
- You now have three environments deployed, 'prd', 'dev' and 'stg'.

---
#### 1.4 Future Changes.
---
Future changes are implemented by creating feature branches and pull requests. 'dev' and 'stg' can be updated directly, but 'prd' must be updated via a PR.

&nbsp;
### 2. The 'Build' Pipeline Workflow
The build pipeline focusses on building the code and creating a docker image ready for deployment. As changes are frequently made, the pipeline 'trigger' is automatic.

---
#### 2.1 Build the 'prd' Branch.
---
a. Update line 20 in src\voting\server.js with a new timestamp.  
b. Push the 'prd' branch to github.  
`git add .`  
`git commit -m "prd build deployment 220608-2025"`  
`git push -u origin prd`  
c. The pipeline '2-voteapp-build' should automatically trigger.

Pipeline Actions:
- Compiles the code, creates a docker image and pushes to ACR.

Output:
- You now have a docker image ready for testing or deployment.

---
#### 2.2 Build the other branches.
---
The steps above can be repeated to build 'dev' and 'stg'. They're covered in the release steps below.

&nbsp;
### 3. The 'Release' Pipeline Workflow

The release pipeline focusses on deploying docker images to Azure Kubernetes Service. For control, this is a manual step where you specify the image tag you want to deploy.

---
#### 3.1 Release the 'prd' Branch.
---
a. Manually run '3-voteapp-release' against the 'prd' branch. Enter the 'Docker Tag' you want to deploy; this is a required field e.g. 20220608.4-prd.

Pipeline Actions:
- Evaluates the branch name and deploys the app to Azure Kubernetes Service (prd environment).

Output:
- You now have the 'prd' environment deployed. Test using the following urls https://prd.rhod3rz.com/ and https://prd.rhod3rz.com/analytics.

---
#### 3.2 Release the 'dev' Branch.
---
It's time to simulate a change ...  

a. Create a new branch 'dev', and switch to it.  
`git checkout -b dev`  
b. Update line 20 in src\voting\server.js with a new timestamp.  
c. Push the 'dev' branch to github.  
`git add .`  
`git commit -m "dev build deployment 220608-2043"`  
`git push -u origin dev`  
d. The pipeline '2-voteapp-build' should automatically trigger; wait for this to finish.  
e. Manually run '3-voteapp-release' against the 'dev' branch. Enter the 'Docker Tag' you want to deploy; this is a required field e.g. 20220608.5-dev.

Pipeline Actions:
- Compiles the code, creates a docker image and pushes to ACR.
- Evaluates the branch name and deploys the app to Azure Kubernetes Service (dev environment).

Output:
- You now have the 'dev' environment deployed. Test using the following url https://dev.rhod3rz.com/ and https://dev.rhod3rz.com/analytics.  
When running the app, notice the timestamp in the 'dev' environment is now the updated one you set in step 3.2b.

---
#### 3.3 Release the 'stg' Branch.
---
It's time to merge the 'dev' changes into the 'stg' branch ...

a. Create a new branch 'stg', and switch to it. This is now a copy of 'dev'.  
`git checkout -b stg`  
b. Commit changes.  
`git push -u origin stg`  
c. The pipeline '2-voteapp-build' should automatically trigger; wait for this to finish.  
d. Manually run '3-voteapp-release' against the 'stg' branch. Enter the 'Docker Tag' you want to deploy; this is a required field e.g. 20220608.8-stg.

Pipeline Actions:
- Compiles the code, creates a docker image and pushes to ACR.
- Evaluates the branch name and deploys the app to Azure Kubernetes Service (stg environment).

Output:
- You now have the 'stg' environment deployed. Test using the following url https://stg.rhod3rz.com/ and https://stg.rhod3rz.com/analytics.  
When running the app, notice the timestamp in the 'stg' environment is now the updated one carried over from 'dev'.

---
#### 3.4. Merge the 'stg' Branch to 'prd' Branch.
---
Assuming there were no issues with the 'stg' deployment it's time to merge those changes into 'prd' ...

a. Create a 'Pull Request' to merge 'stg' into 'prd' and delete the 'stg' branch from GitHub.  
b. Delete the 'dev' branch from GitHub.  
c. Delete the 'dev' and 'stg' branch from local Git e.g.  
`git checkout prd`  
`git branch -d dev`  
`git branch -d stg`  
`git remote prune origin`  
`git pull origin prd`  
d. The pipeline '2-todolist-build' should automatically trigger; wait for this to finish.  
e. Manually run '3-todolist-release' against the 'prd' branch. Enter the 'Docker Tag' you want to deploy; this is a required field e.g. 20220608.9-prd.

Pipeline Actions:
- Compiles the code, creates a docker image and pushes to ACR.
- Evaluates the branch name and deploys the app to Azure Kubernetes Service (prd environment).

Output:
- You've just updated 'prd'. Test as before e.g. https://prd.rhod3rz.com/ and https://prd.rhod3rz.com/analytics.  
When running the app, notice the version number in the 'prd' environment is now the updated one you pushed through 'dev' and 'stg'.

---
#### 3.5. Emergency Rollback.
---
Instructions:

Aargh something has gone wrong and been missed in testing! You need to rollback to the previous version asap ...

a. View the rollout history to see previous versions. Note: 'Change-Cause' is populated from the deployment yaml file, and updated to the correct version via pipeline.  
`kubectl rollout history --namespace=voting deploy/voting-app`  
b. Drill into a version e.g. to confirm which image it's using:  
`kubectl rollout history --namespace=voting deploy/voting-app --revision=1`  
c. Rollback:  
`kubectl rollout undo --namespace=voting deploy/voting-app --to-revision=1`  

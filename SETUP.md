# Setup Guide — gcp-hcp-terraform

Follow in order. Steps 1, 3, 4, 5 are UI/console steps only you can click through.
Step 2 is a script you run once locally.

---

## Step 1 — Create the HCP Terraform organization
1. Go to https://app.terraform.io/ → sign up / log in.
2. Create org: **`gcpcloudhub`** (matches `versions.tf`).
3. Skip the "create workspace" wizard for now — you'll do that in Step 4.

---

## Step 2 — Workload Identity Federation (run once, locally)

Replace `HCP_TF_ORG` if you named your org differently. Run this for **each** project (`gcphub-dev`, `gcphub-prod`) — substitute `PROJECT_ID` accordingly.

```bash
export PROJECT_ID="gcphub-dev"     # then repeat whole block with gcphub-prod
export ENV="dev"                    # then "prod"
export POOL_ID="hcp-terraform-pool"
export PROVIDER_ID="hcp-terraform-provider"
export SA_NAME="hcp-tf-deployer-${ENV}"

# 1. Enable required APIs
gcloud services enable iamcredentials.googleapis.com run.googleapis.com \
  artifactregistry.googleapis.com compute.googleapis.com cloudkms.googleapis.com \
  --project="${PROJECT_ID}"

# 2. Create the Workload Identity Pool
gcloud iam workload-identity-pools create "${POOL_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="HCP Terraform Pool"

# 3. Create the OIDC Provider trusting HCP Terraform's issuer
gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_ID}" \
  --display-name="HCP Terraform Provider" \
  --issuer-uri="https://app.terraform.io" \
  --attribute-mapping="google.subject=assertion.sub,attribute.terraform_organization_id=assertion.terraform_organization_id,attribute.terraform_workspace_id=assertion.terraform_workspace_id" \
  --attribute-condition="assertion.terraform_organization_name=='gcpcloudhub'"

# 4. Create the deploy service account (least privilege — scoped roles only)
gcloud iam service-accounts create "${SA_NAME}" \
  --project="${PROJECT_ID}" \
  --display-name="HCP Terraform Deployer (${ENV})"

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

for ROLE in roles/run.admin roles/artifactregistry.admin \
            roles/compute.networkAdmin roles/iam.serviceAccountUser \
            roles/iam.serviceAccountAdmin roles/cloudkms.admin; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${ROLE}"
done

# 5. Allow the WIF pool to impersonate this service account
PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")

gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/*"

# 6. Print the provider resource name — you'll need this in Step 4
echo "TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL = ${SA_EMAIL}"
echo "TFC_GCP_WORKLOAD_PROVIDER_NAME    = projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"
```

Save both printed values for each environment — you'll paste them into the matching HCP Terraform workspace in Step 4.

---

## Step 3 — Connect GitHub to HCP Terraform
1. In the `gcpcloudhub` org → **Settings → VCS Providers → Add VCS Provider** → GitHub → authorize and select the `gcp-hcp-terraform` repo.

---

## Step 4 — Create the two workspaces

Repeat for `gcphub-dev-cloudrun` and `gcphub-prod-cloudrun`:

1. **New → Workspace → Version control workflow** → select the connected `gcp-hcp-terraform` repo.
2. **Advanced options:**
   - Terraform Working Directory: `infra`
   - VCS branch: `dev` for the dev workspace, `main` for the prod workspace
3. After creation, go to workspace **Settings → General → Tags** → add tag `gcp-hcp-terraform` (required — this is what `versions.tf`'s `workspaces { tags = [...] }` resolves against).
4. Go to **Variables** and add, as **Environment variables**:
   - `TFC_GCP_PROVIDER_AUTH` = `true`
   - `TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL` = *(value printed in Step 2, for this environment)*
   - `TFC_GCP_WORKLOAD_PROVIDER_NAME` = *(value printed in Step 2, for this environment)*
5. Add, as **Terraform variables**:
   - `project_id` = `gcphub-dev` (or `gcphub-prod`)
   - `region` = `asia-south1`
   - `environment` = `dev` (or `prod`)
   - For the prod workspace only: `min_instances` = `1`
6. **Dev workspace only:** Settings → General → enable **Auto Apply**.
   **Prod workspace:** leave Auto Apply **off** (manual confirm required — Phase 20.5).

---

## Step 5 — Branch protection on GitHub
Repo → Settings → Branches → add rule for `dev` and `main`:
- Require status checks: `validate`, `tflint`, `checkov` (from `pre-flight.yml`)
- Require PR before merging

---

## Step 6 (optional, once you're ready) — Push a real container image
The default `container_image` variable points at Google's public hello-world demo image so the first apply works with zero extra setup. When ready to deploy your own app:
```bash
gcloud auth configure-docker asia-south1-docker.pkg.dev
docker build -t asia-south1-docker.pkg.dev/gcphub-dev/gcphub-dev-repo/app:latest .
docker push asia-south1-docker.pkg.dev/gcphub-dev/gcphub-dev-repo/app:latest
```
Then override the `container_image` Terraform variable in the workspace to point at it.

---

## First run
```bash
git checkout -b dev
git add infra .github SETUP.md
git commit -m "Initial HCP Terraform pipeline: VPC, Artifact Registry, Cloud Run"
git push origin dev
```
Open a PR into `dev` on GitHub (or push directly to `dev` if it's your default branch for now) — watch pre-flight checks run, then check the HCP Terraform UI for the triggered plan.

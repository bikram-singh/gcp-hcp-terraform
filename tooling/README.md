# tooling

Small scripts supporting the API-driven workflow demo (`gcphub-api-demo` workspace) -- packages the manual `Invoke-RestMethod` sequence used during development into a reusable tool, closer to what a real custom CI integration would look like.

## trigger-api-run.ps1

Triggers an HCP Terraform run purely via the REST API: creates a configuration version, uploads local `.tf` files, and starts a run -- no VCS connection, no local `terraform` CLI required on the calling machine.

```powershell
# Apply
./trigger-api-run.ps1 -WorkspaceId "ws-QVnbJSD7sEAtsZe9" -ConfigDir "." -Message "Deploy via pipeline"

# Destroy
./trigger-api-run.ps1 -WorkspaceId "ws-QVnbJSD7sEAtsZe9" -ConfigDir "." -Destroy -Message "Teardown demo"
```

Reads an API token from the same credentials file `terraform login` writes to (`%APPDATA%\terraform.d\credentials.tfrc.json`) unless `-Token` is passed explicitly.

Used to demonstrate the third HCP Terraform workflow type (API-driven), alongside the VCS-driven workspaces (`gcphub-dev`, `gcphub-prod`, `gcphub-dev-monitoring`) and CLI-driven usage (`terraform login` + local `plan`) elsewhere in this project.

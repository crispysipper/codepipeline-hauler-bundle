# codepipeline-hauler-bundle

AWS CodePipeline / CodeBuild job that builds a Hauler airgap haul from
[`manifests/inventory.yaml`](manifests/inventory.yaml) and uploads it to S3.

Compatible with `cyber-radar-platform` bootstrap
(`custom_hauler_artifact` / `bootstrap_hauler_artifact`).

## Flow

```text
GitHub → CodeBuild → hauler store sync/save → S3 (.tar.zst)
```

| Piece | Path |
| --- | --- |
| Inventory | `manifests/inventory.yaml` |
| Build | `scripts/bundle.sh` |
| Buildspec | `buildspec/hauler-bundle.yml` |
| Pipeline IaC | `infra/terraform/` |

## Output

```text
s3://$ARTIFACT_BUCKET/hauler-bundles/$NAME-$DATE-$SHORT_SHA/$NAME-$DATE-$SHORT_SHA.tar.zst
s3://$ARTIFACT_BUCKET/hauler-bundles/$NAME-latest.tar.zst
```

`hauler.env` in the CodeBuild artifact contains `HAULER_S3_URI=…`.

```hcl
bootstrap_hauler_artifact = "s3://…/hauler-bundles/rke2-bootstrap-latest.tar.zst"
```

## Deploy

```bash
cd infra/terraform
cp environments/dev.tfvars.example environments/dev.tfvars
# set github_owner + codestar_connection_arn
tofu init
tofu apply -var-file=environments/dev.tfvars
```

Optional: `docker_config_json_secret_arn` for private upstream image pulls
(Iron Bank, Docker Hub, Artifactory).

## Notes

- Chart entries must use HTTP(S) or `oci://` repos. Git chart sources are
  skipped (Hauler store sync cannot clone them).
- Edit the inventory and push to the configured branch to rebuild.

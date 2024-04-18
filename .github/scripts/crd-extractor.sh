#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Create temp folder for CRDs
TMP_CRD_DIR=$HOME/.datree/crds
mkdir -p "$TMP_CRD_DIR"

# Create final schemas directory
SCHEMAS_DIR=$HOME/.datree/crdSchemas
mkdir -p "$SCHEMAS_DIR"
cd "$SCHEMAS_DIR" || exit 1

# Create array to store CRD kinds and groups
ORGANIZE_BY_GROUP=true
declare -A CRD_GROUPS 2>/dev/null || false

# Extract CRDs from cluster
NUM_OF_CRDS=0
while read -r crd
do
    filename=${crd%% *}
    kubectl get crds "$filename" -o yaml > "$TMP_CRD_DIR/$filename.yaml" 2>&1
    kubectl get crds "$filename" -o yaml | sed '1,/spec:/d' > "$TMP_CRD_DIR/$filename.yaml.tmp" 2>&1

    resourceKind=$(grep "^ *kind:" "$TMP_CRD_DIR/$filename.yaml.tmp" | awk 'NR==1{print $2}' | tr '[:upper:]' '[:lower:]')
    resourceGroup=$(grep "group:" "$TMP_CRD_DIR/$filename.yaml.tmp" | awk 'NR==1{print $2}')

    # Save name and group for later directory organization
    CRD_GROUPS["$resourceKind"]="$resourceGroup"

    let ++NUM_OF_CRDS
done < <(kubectl get crds 2>&1 | sed -n '/NAME/,$p' | tail -n +2)

# If no CRDs exist in the cluster, exit
if [ $NUM_OF_CRDS == 0 ]; then
    printf "No CRDs found in the cluster, exiting...\n"
    exit 0
fi

# Convert crds to jsonSchema
python3 "${SCRIPT_DIR}/openapi2jsonschema.py" "$TMP_CRD_DIR"/*.yaml
conversionResult=$?

# Copy and rename files to support kubeval
rm -rf "$SCHEMAS_DIR/master-standalone"

# Organize schemas by group
if [ $ORGANIZE_BY_GROUP == true ]; then
    for schema in "$SCHEMAS_DIR"/*.json
    do
    crdFileName=$(basename "$schema" .json)
    crdKind=${crdFileName%%_*}
    crdGroup=${CRD_GROUPS[$crdKind]}
    mkdir -p "$crdGroup"
    mv "$schema" "./$crdGroup"
    done
fi

if [ $conversionResult == 0 ]; then
    cp -r "${SCHEMAS_DIR}"/* "${SCRIPT_DIR}/../.."
    printf "Succesfully converted %s CRDs to JSON schema\n" "${NUM_OF_CRDS}"
fi

rm -rf "$TMP_CRD_DIR"

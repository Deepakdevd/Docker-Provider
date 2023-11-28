#!/bin/bash

# Define the pod name and namespace
POD_DOTNET_NAME="dotnet-test-app"
POD_JAVA_NAME="customer-java-test-app"
POD_NODEJS_NAME="test-app-nodejs"
NAMESPACE="default"

# Define the property to check for
PROPERTY="APPLICATIONINSIGHTS_CONNECTION_STRING"

DOTNET_POD_NAME=$(kubectl get pods -n "$NAMESPACE" -o custom-columns=NAME:.metadata.name | grep "$POD_DOTNET_NAME")
JAVA_POD_NAME=$(kubectl get pods -n "$NAMESPACE" -o custom-columns=NAME:.metadata.name | grep "$POD_JAVA_NAME")
# NODEJS_POD_NAME=$(kubectl get pods -n test-ns -o custom-columns=NAME:.metadata.name | grep "$POD_NODEJS_NAME")

echo "$PROPERTY"
echo "$DOTNET_POD_NAME"
echo "$JAVA_POD_NAME"

checkit() {
    local podName="$1"  # The first argument to the function is stored in 'name'
    POD_YAML=$(kubectl get pod "$podName" -n "$NAMESPACE" -o yaml)

    # Check for the property
    if echo "$POD_YAML" | grep -q "$PROPERTY"; then
        echo "Property $PROPERTY found in pod $POD_NAME"
        # You can add additional commands here to process the property
    else
        echo "Property $PROPERTY not found in pod $POD_NAME"
    fi
}

checkit "$DOTNET_POD_NAME" 
checkit "$JAVA_POD_NAME" 


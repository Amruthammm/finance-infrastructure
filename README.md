az login --use-device-code
az deployment sub create --location canadacentral --template-file main.bicep --parameters environment=dev

az deployment sub create --location canadacentral --template-file main.bicep --parameters environment=dev

az deployment sub create --location canadacentral --template-file main.bicep --parameters environment=dev --parameters adminUsername=testnewuser --parameters adminPassword="Test@123Password"